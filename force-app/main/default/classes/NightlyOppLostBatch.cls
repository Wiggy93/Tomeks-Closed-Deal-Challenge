public with sharing class NightlyOppLostBatch implements Database.Batchable<sObject>{
    
    public Database.QueryLocator start (Database.BatchableContext bc) {
        System.debug('Start nightly setting of opportunities to closed lost');
        String query = 'SELECT Id, StageName FROM Opportunity' + 
                        ' WHERE CloseDate = TODAY' + 
                        ' AND isWon = false' + 
                        (Test.isRunningTest() ? ' LIMIT 200' : '');
        return Database.getQueryLocator(query);
    }

    public void execute (Database.BatchableContext bc, List<Opportunity> opps) {
        System.debug('Executing nightly opps to closed lost');
        System.debug('Batch size: ' + opps.size());
        List<Opportunity> updateOpps = new List<Opportunity>();
        if ( opps.size() > 0 ) {
            for ( Opportunity o : opps ) {
                o.StageName = 'Closed Lost';
                updateOpps.add(o);
            }
            update updateOpps;
            System.debug('Executed nightly update.');
        }
    }

    public void finish (Database.BatchableContext bc) {
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :bc.getJobId()];
        System.debug('>>> Finished: ' + job.Status);
        System.debug('>>> Errors: ' + job.NumberOfErrors);
    }

}