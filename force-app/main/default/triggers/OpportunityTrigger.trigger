// PMD didn't smite you? https://docs.pmd-code.org/latest/pmd_rules_apex_bestpractices.html#avoidlogicintrigger

trigger OpportunityTrigger on Opportunity (after insert, after update) {
     //new OpportunityTriggerHandler().run();
   

     //would it be better to put if (opp.stageName == closedWon || stagename == closed lost) logic here to avoid wasting CPU time if opp doesn't trigger counter 

    //add before update, add trigger.old

    //List<Opportunity> opps = new List<Opportunity>();
    Set<Id> ownerIds = new Set<Id>();
    for (Opportunity o : Trigger.new) {
        //1. Opp has changed from not closed to closed

        /*  Common trick to save CPU and spam the debug log less is a helper variable
                Opportunity old = Trigger.oldMap.get(o.Id);
            instead of keep accessing the map over and over
        */
        Boolean toClosed = o.IsClosed && !Trigger.oldMap.get(o.Id).IsClosed;

        //2. Opp has changed from closed to not closed
        Boolean fromClosed = !o.IsClosed && Trigger.oldMap.get(o.Id).IsClosed;

        //4. Check not going from closed won to closed lost or vice versa
        Boolean fromLostToWon = o.IsWon && Trigger.oldMap.get(o.Id).StageName == 'Closed Lost';

        Boolean toLostFromWon = o.StageName == 'Closed Lost' && Trigger.oldMap.get(o.Id).IsWon;

        //3. Opp closed date is current month
        Boolean currentMonth = o.CloseDate.month() == Date.today().month() && o.CloseDate.year() == Date.today().year();


        if ((toClosed || fromClosed || fromLostToWon || toLostFromWon) && currentMonth) {
            ownerIds.add(o.OwnerId);
        }
        /*  Pesky tester would fail you on
            - not clearing the "rollup" when date changes to future.
            - And if opportunity owner changes you need to update "+1" on new guy, "-1" on old guy.
                Whether you'd do it like that as "+1" or by sending trigger.oldMap.get(o.Id).OwnerId to the helper method too.
            - and no handling on inserting already won opps
            - deleting opps
            - and then restoring them from the bin

            This can grow very nasty very quick so a bit "pro" move for update-ish scenario would be something like

                for(Opportunity o : Trigger.new) {
                    Opportunity old = Trigger.oldMap.get(o.Id);
                    if(o.StageName != old.StageName || o.CloseDate != old.CloseDate || o.OwnerId != old.OwnerId){
                        ownerIds.add(o.OwnerId);
                        ownerIds.add(old.OwnerId);
                    }
                }
            It's not great, it could use the "was either old or new close date this month", "was either owner a Sales guy" but that's optimisations that could go later
            The main thing is that the intent is more readable
        */
    }
    if(!ownerIds.isEmpty()) {

        OpportunityTriggerHandlerException.oppDealCounter(ownerIds);
    }
}