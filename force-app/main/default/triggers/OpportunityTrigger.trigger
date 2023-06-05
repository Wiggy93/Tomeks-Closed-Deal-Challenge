trigger OpportunityTrigger on Opportunity (after insert, after update) {
     //new OpportunityTriggerHandler().run();
   

     //would it be better to put if (opp.stageName == closedWon || stagename == closed lost) logic here to avoid wasting CPU time if opp doesn't trigger counter 

    //List<Opportunity> opps = new List<Opportunity>();
    Set<Id> ownerIds = new Set<Id>();
    for (Opportunity o : Trigger.new) {
        //1. Opp has changed from not closed to closed
        Boolean toClosed = o.IsClosed && !Trigger.oldMap.get(o.Id).IsClosed;

        //2. Opp has changed from closed to not closed
        Boolean fromClosed = !o.IsClosed && Trigger.oldMap.get(o.Id).IsClosed;

        //4. Check not going from closed won to closed lost or vice versa
        Boolean fromLostToWon = o.IsWon && Trigger.oldMap.get(o.Id).StageName == 'Closed Lost';

        Boolean toLostFromWon = o.StageName == 'Closed Lost' && Trigger.oldMap.get(o.Id).IsWon;

        //3. Opp closed date is current month
        Boolean currentMonth = o.CloseDate.month() == Date.today().month() && o.CloseDate.year() == Date.today().year();

        
        if ((toClosed || fromClosed || !fromLostToWon || !toLostFromWon) && currentMonth) {
            ownerIds.add(o.OwnerId);
        }
    }
    if(!ownerIds.isEmpty()) {

        OpportunityTriggerHandlerException.oppDealCounter(ownerIds);
    }
}