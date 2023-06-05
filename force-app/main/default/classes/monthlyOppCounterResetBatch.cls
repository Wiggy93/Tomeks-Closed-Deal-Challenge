public with sharing class monthlyOppCounterResetBatch implements Database.Batchable<sObject>{
    /*  It's convention to write class names CamelCase so "Monthly...", PMD should have smitten you with https://docs.pmd-code.org/latest/pmd_rules_apex_codestyle.html#classnamingconventions ?

        And I'd call it just "UserOpportunityResetBatch" or something. Make "monthly" the admin's responsibility when they schedule the job.
        They'll decide they want to follow different fiscal period for paying commission to sales reps or something and your class name will be wrong.
    */
    public Database.QueryLocator start (Database.BatchableContext ctx) {
        System.debug('>>> Start monthly reset of Salespeoples Opportunity Counters');
        String query = 'SELECT Id, monthlyOppCounter__c FROM User WHERE UserRoleId != null AND monthlyOppCounter__c != 0' + (Test.isRunningTest() ? ' LIMIT 3' : '' );
        /*  That's not really to the spec, I'd expect something like WHERE UserRole.Name LIKE '%Sales%'
            Roughly speaking it's better form to write start with real queries, not bunch of text hacked together with a string.
            
            If you make a real query
                Database.getQueryLocator([SELECT Id, monthlyOppCounter__c FROM User]);
            It becomes a compile-time reference to the field. Salesforce will react better when you click "Where is this used?" in field definition, will warn the user when they try to delete it...
            Which is well, annoying to developer but compile-time is better than runtime exception ;)

            In your case it becomes slightly tricky because tests see all Users and there could be > 200 in the org. So probably some form of Test.isRunningTest is unavoidable but still - I'd probably do it
            Database.QueryLocator ql;
            if(Test.isRunningTest()){
                ql = Database.getQueryLocator([SELECT Id, monthlyOppCounter__c FROM User WHERE LastName = 'Test' AND UserRole.Name LIKE '%Sales%' AND monthlyOppCounter__c != 0]);
            } else {
                ql = Database.getQueryLocator([SELECT Id, monthlyOppCounter__c FROM User WHERE UserRole.Name LIKE '%Sales%' AND monthlyOppCounter__c != 0]);
            }
            return ql;
        */
        return Database.getQueryLocator(query);
    }

    public void execute (Database.BatchableContext ctx, List<User> users) {
        System.debug('Executing monthlyOppCounterResetBatch');
        System.debug('>>> Execute Batch size: ' + users.size());
        List<User> userList = new List<User>();
        if (users.size() > 0) { // it'll always be > 0
            for ( User u : users ) {
                u.monthlyOppCounter__c = 0;
                userList.add(u);
            }
            update userList;
            System.debug('Executed Update');
        }

        /*  Life is too short to patiently add them to a helper list. Just update the original
            for ( User u : users ) {
                u.monthlyOppCounter__c = 0;
            }
            update users;
        */
    }

    public void finish (Database.BatchableContext ctx) {
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, TotalJobItems FROM AsyncApexJob WHERE Id = :ctx.getJobId()];
        System.debug('>>> Finished: ' + job.Status);
        System.debug('>>> Errors: ' + job.NumberOfErrors);
        System.debug('>>> Number of Items processed: ' + job.TotalJobItems);
    }
    /*  Hm... OK but equally admin can see it in setup. To see this they'd need debug logs on anyway?
        "Less is more", empty method or go full blown some email sent with success/failure

        Missed opportunity to add implements Database.RaisesPlatformEvents
    */
}