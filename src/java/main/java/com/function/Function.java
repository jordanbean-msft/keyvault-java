package com.function;

import com.microsoft.azure.functions.ExecutionContext;
import com.microsoft.azure.functions.annotation.EventGridTrigger;
import com.microsoft.azure.functions.annotation.FunctionName;
import com.microsoft.graph.authentication.TokenCredentialAuthProvider;
import com.microsoft.graph.models.ApplicationAddPasswordParameterSet;
import com.microsoft.graph.models.ApplicationRemovePasswordParameterSet;
import com.microsoft.graph.models.PasswordCredential;
import okhttp3.Request;
import com.microsoft.graph.requests.GraphServiceClient;

import java.util.UUID;
import java.time.OffsetDateTime;
import java.util.Arrays;

import com.azure.identity.DefaultAzureCredential;
import com.azure.identity.DefaultAzureCredentialBuilder;

import com.azure.security.keyvault.secrets.SecretClient;
import com.azure.security.keyvault.secrets.SecretClientBuilder;
import com.azure.security.keyvault.secrets.models.KeyVaultSecret;
import com.azure.security.keyvault.secrets.models.SecretProperties;

public class Function {
  @FunctionName("rotate-secret")
  public void run(
      @EventGridTrigger(name = "event") EventSchema event, final ExecutionContext context) {
    context.getLogger().info("Event content: ");
    context.getLogger().info("Subject: " + event.subject);
    context.getLogger().info("Time: " + event.eventTime);
    context.getLogger().info("Id: " + event.id);
    context.getLogger().info("Data: " + event.data);

    String appRegistrationObjectId = event.subject;

    String keyVaultUri = System.getenv("KEY_VAULT_URI");
    String managedIdentityClientId = System.getenv("MANAGED_IDENTITY_CLIENT_ID");

    DefaultAzureCredential defaultCredential = new DefaultAzureCredentialBuilder()
        .managedIdentityClientId(managedIdentityClientId)
        .build();

    SecretClient secretClient = new SecretClientBuilder()
        .vaultUrl(keyVaultUri)
        .credential(defaultCredential)
        .buildClient();

    String previousClientSecretKeyId = secretClient
        .getSecret(appRegistrationObjectId)
        .getProperties()
        .getContentType();
    PasswordCredential newPasswordCredential = SetAppRegistrationClientSecret(context, appRegistrationObjectId,
        previousClientSecretKeyId);

    if (newPasswordCredential != null) {
      KeyVaultSecret newKeyVaultSecret = new KeyVaultSecret(appRegistrationObjectId, newPasswordCredential.secretText);
      newKeyVaultSecret.setProperties(new SecretProperties()
          .setContentType(newPasswordCredential.keyId.toString())
          .setExpiresOn(newPasswordCredential.endDateTime));

      try {
        context.getLogger().info("Updating secret in Key Vault for " + appRegistrationObjectId);
        secretClient.setSecret(newKeyVaultSecret);
      } catch (Exception e) {
        context.getLogger().info("Error setting secret: " + e.getMessage());
      }
    }
  }

  private PasswordCredential SetAppRegistrationClientSecret(final ExecutionContext context,
      String appRegistrationObjectId,
      String previousClientSecretKeyId) {
    String managedIdentityClientId = System.getenv("MANAGED_IDENTITY_CLIENT_ID");

    DefaultAzureCredential defaultCredential = new DefaultAzureCredentialBuilder()
        .managedIdentityClientId(managedIdentityClientId)
        .build();

    GraphServiceClient<Request> graphClient = GraphServiceClient.builder()
        .authenticationProvider(
            new TokenCredentialAuthProvider(Arrays.asList("https://graph.microsoft.com/.default"), defaultCredential))
        .buildClient();

    PasswordCredential passwordCredential = new PasswordCredential();

    Long numberOfDaysUntilExpiry = Long.parseLong(System.getenv("NUMBER_OF_DAYS_UNTIL_EXPIRY"));
    passwordCredential.displayName = "Set via automation";
    passwordCredential.endDateTime = OffsetDateTime.now().plusDays(numberOfDaysUntilExpiry);

    try {
      context.getLogger().info("Rotating client secret for app registration: " + appRegistrationObjectId);

      // create new client secret
      passwordCredential = graphClient.applications(appRegistrationObjectId)
          .addPassword(
              ApplicationAddPasswordParameterSet
                  .newBuilder()
                  .withPasswordCredential(passwordCredential)
                  .build())
          .buildRequest().post();

      // remove old client secret
      graphClient.applications(appRegistrationObjectId)
          .removePassword(
              ApplicationRemovePasswordParameterSet
                  .newBuilder()
                  .withKeyId(UUID.fromString(previousClientSecretKeyId))
                  .build())
          .buildRequest()
          .post();
    } catch (Exception e) {
      context.getLogger().info("Error rotating client secret for app registration: " + appRegistrationObjectId);
      context.getLogger().info(e.getMessage());
      return null;
    }

    return passwordCredential;
  }
}
