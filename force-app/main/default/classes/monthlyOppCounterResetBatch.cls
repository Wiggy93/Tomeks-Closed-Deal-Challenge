public with sharing class monthlyOppCounterResetBatch implements Database.Batchable<sObject>{

    public Database.QueryLocator start (Database.BatchableContext ctx) {
        System.debug('>>> Start monthly reset of Salespeoples Opportunity Counters');
        String query = 'SELECT Id, monthlyOppCounter__c FROM User WHERE UserRoleId != null AND monthlyOppCounter__c != 0' + (Test.isRunningTest() ? ' LIMIT 3' : '' );
        return Database.getQueryLocator(query);
    }

    public void execute (Database.BatchableContext ctx, List<User> users) {
        System.debug('Executing monthlyOppCounterResetBatch');
        System.debug('>>> Execute Batch size: ' + users.size());
        List<User> userList = new List<User>();
        if (users.size() > 0) {
            for ( User u : users ) {
                u.monthlyOppCounter__c = 0;
                userList.add(u);
            }
        update userList;
        System.debug('Executed Update');
        }
    }

    public void finish (Database.BatchableContext ctx) {
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :ctx.getJobId()];
        System.debug('>>> Finished: ' + job.Status);
        System.debug('>>> Errors: ' + job.NumberOfErrors);
        System.debug('>>> Number of Items processed: ' + job.TotalJobItems);
    }
    
}