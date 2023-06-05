trigger OpportunityTrigger on Opportunity (after insert, after update) {
     //new OpportunityTriggerHandler().run();
   

     //would it be better to put if (opp.stageName == closedWon || stagename == closed lost) logic here to avoid wasting CPU time if opp doesn't trigger counter 
    OpportunityTriggerHandlerException.oppDealCounter(Trigger.new);
}