@isTest
public with sharing class NightlyOppLostScheduler_Tests {
    
    @isTest
    static void scheduleTest() {
        String sch = '0 0 0 3 6 ? 2029';

         List<AsyncApexJob> preScheduleJobs = [
            SELECT Id, ApexClassId, ApexClass.Name, Status, JobType
            FROM AsyncApexJob
        ];
        System.assertEquals(0, preScheduleJobs.size(), 'no jobs should be queued prior to test starting');

        Test.startTest();
            String jobId = System.schedule('NightlyOppLostScheduler test', sch, new NightlyOppLostScheduler());
        Test.stopTest();

        List<AsyncApexJob> jobsScheduled = [
            SELECT Id, ApexClassID, ApexClass.Name, Status, JobType 
            FROM AsyncApexJob 
            WHERE JobType = 'ScheduledApex'
            ];
        System.assertEquals(1, jobsScheduled.size(), 'expecting one scheduled job');
        System.assertEquals('NightlyOppLostScheduler', jobsScheduled[0].ApexClass.Name, 'expecting specific scheduled job');

        // check apex batch is in the job list
        List<AsyncApexJob> jobsApexBatch = [
            SELECT Id, ApexClassID, ApexClass.Name, Status, JobType 
            FROM AsyncApexJob 
            WHERE JobType = 'BatchApex'
            ];
        System.assertEquals(1, jobsApexBatch.size(), 'expecting one apex batch job');
        System.assertEquals('NightlyOppLostBatch', jobsApexBatch[0].ApexClass.Name, 'expecting specific batch job');
    }
}