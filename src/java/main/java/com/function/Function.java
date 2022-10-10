package com.function;

import com.microsoft.azure.functions.ExecutionContext;
import com.microsoft.azure.functions.annotation.EventGridTrigger;
import com.microsoft.azure.functions.annotation.FunctionName;

public class Function {
  @FunctionName("rotate-secret")
  public void run(
      @EventGridTrigger(name = "event") EventSchema event, final ExecutionContext context) {
    context.getLogger().info("Event content: ");
    context.getLogger().info("Subject: " + event.subject);
    context.getLogger().info("Time: " + event.eventTime);
    context.getLogger().info("Id: " + event.id);
    context.getLogger().info("Data: " + event.data);
  }
}
