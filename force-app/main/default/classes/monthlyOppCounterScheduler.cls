public with sharing class monthlyOppCounterScheduler implements Schedulable{
     
    public void execute (SchedulableContext sc) {

        //Do I need to catch LimitExceptions?
        monthlyOppCounterResetBatch batch = new monthlyOppCounterResetBatch();
        Database.executeBatch(batch, 200);
    }
}