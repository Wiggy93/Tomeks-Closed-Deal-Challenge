public with sharing class monthlyOppCounterScheduler implements Schedulable{
     
    public void execute (SchedulableContext sc) {

        //Do I need to catch LimitExceptions?
        // No (and governor limits are uncatchable anyway)
        monthlyOppCounterResetBatch batch = new monthlyOppCounterResetBatch();
        Database.executeBatch(batch, 200);
    }
    /* It's not wrong but "pro" move would be to merge this into 1 class, make
        public with sharing class monthlyOppCounterResetBatch implements Database.Batchable<sObject>, Database.RaisesPlatformEvents, Schedulable
        And when I have them in 1 class the lazy syntax is just

        public void execute (SchedulableContext sc) {
            Database.executeBatch(this);
        }
    */
}