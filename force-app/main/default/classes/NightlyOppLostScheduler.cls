public with sharing class NightlyOppLostScheduler implements Schedulable {
    public void execute (SchedulableContext sc) {

        //Do I need to catch LimitExceptions?
        //NightlyOppLostBatch batch = new NightlyOppLostBatch();
        Database.executeBatch(new NightlyOppLostBatch(), 200);
    }
    
}