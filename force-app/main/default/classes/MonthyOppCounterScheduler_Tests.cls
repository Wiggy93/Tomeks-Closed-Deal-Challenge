@isTest
public with sharing class MonthyOppCounterScheduler_Tests {

    @isTest
    static void scheduleTest() {
        User admin = [
            SELECT Id, FirstName, UserRole.Name, ProfileId
            FROM User
            WHERE Profile.Name = 'System Administrator'
        ];

        //Want to just test the monthlyOppCounterResetBatch has been added to the queue, as the batch class is tested elsewhere
        //Therefore no test data required, don't care what the results of the batch test through back.

        // CRON expression: midnight on March 15. Because this is a test, 
        // job is supposed to execute immediately after Test.stopTest()
        String cronExpr = '0 0 0 1 7 ? 2023';

        List<AsyncApexJob> preScheduleJobs = [
            SELECT Id, ApexClassId, ApexClass.Name, Status, JobType
            FROM AsyncApexJob
        ];
        System.assertEquals(0, preScheduleJobs.size(), 'no jobs should be queued prior to test starting'); // this will crash in any decent org with existing jobs, you'd need something like "WHERE JobName = 'MonthyOppCounterScheduler test'"

        Test.startTest();
            String jobId = System.schedule('MonthyOppCounterScheduler test', cronExpr, new monthlyOppCounterScheduler());
        Test.stopTest();

        // Check schedulable is in the job list
        List<AsyncApexJob> jobsScheduled = [
            SELECT Id, ApexClassID, ApexClass.Name, Status, JobType 
            FROM AsyncApexJob 
            WHERE JobType = 'ScheduledApex'
            ];
        System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
        System.assertEquals('monthlyOppCounterScheduler', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');

        // check apex batch is in the job list
        List<AsyncApexJob> jobsApexBatch = [
            SELECT Id, ApexClassID, ApexClass.Name, Status, JobType 
            FROM AsyncApexJob 
            WHERE JobType = 'BatchApex' // Again, any mature org will see other batch jobs on the list, you'd need to filter it more. WHERE ApexClass.Name = 'monthlyOppCounterResetBatch' should work
            // I mean why do it in apex if you can offload it on database, make less network traffic to your application
            ];
        System.assertEquals(1, jobsApexBatch.size(), 'expecting one apex batch job');
        System.assertEquals('monthlyOppCounterResetBatch', jobsApexBatch[0].ApexClass.Name, 'expecting specific batch job');
    }
}