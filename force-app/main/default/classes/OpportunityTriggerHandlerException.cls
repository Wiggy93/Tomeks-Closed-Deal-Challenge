public with sharing class OpportunityTriggerHandlerException extends Exception{

    //Assume 1 user triggering update to opportunity
    //Assume can go into negative Opp Counts if you're a really bad salesperson that month.

    //implements schedulable for 1st month logic to reset all user.dealCounter = 0;

    public static void oppDealCounter(Set<Id> ownerIds) {

        Savepoint sp = Database.setSavepoint();

        AggregateResult[] groupedOpportuniteis = [
            SELECT Count(Id) oppCount, OwnerId ownerId
            FROM Opportunity
            WHERE OwnerId IN :ownerIds
            AND IsWon = TRUE
            AND CloseDate = THIS_MONTH
            GROUP BY OwnerId
        ];

        List<User> users = new List<User>();

        for (AggregateResult arr : groupedOpportuniteis) {
            users.add(
                new User(
                    Id                      = (Id) arr.get('ownerId'),
                    monthlyOppCounter__c    = (Decimal) arr.get('oppCount')
                )
            );
        }

        update users;

        // //List<Opportunity> oppList = (List<Opportunity>) oppTriggers;
        
        // List<User> owners = [
        //     SELECT  Id, monthlyOppCounter__c, 
        //         (SELECT Id, IsWon, IsLost
        //         FROM Opportunity

        //         )
        //     FROM User
        //     WHERE Id IN :ownerIds
        //     AND UserRole.Name LIKE '%Sales%' 

        // ];
                
        // System.debug(owners);
        
        // // Appropriate Location of try statement???
        // try {
        //     //get trigger.old
        //     if ( ownerIds[0].UserRoleId == null) {//owners
        //         ownerIds[0].UserRoleId.addError('Please have a Role assigned to your user account.');//owners
        //     }
        //     if ( ownerIds.size() > 0) {//owners
        //         User u                 = new User(Id = ownerIds[0].Id);
        //         u.UserRoleId           = ownerIds[0].UserRoleId;
        //         u.monthlyOppCounter__c = ownerIds[0].monthlyOppCounter__c;
        //         System.debug(u);
                
        //         if (u.monthlyOppCounter__c == null) {
        //             u.monthlyOppCounter__c = 0;
        //         }

        //         for (Opportunity o : oppList) {
        //             if ( o.StageName == 'Closed Won' ) {
        //                 u.monthlyOppCounter__c++;
        //             } else if ( o.StageName == 'Closed Lost' ) {
        //                 u.monthlyOppCounter__c--;
        //             }
        //         }
        //         System.debug(u);
        //         update u;
        //     } 
       
        // } catch (System.ListException e) {
        //     Database.rollback(sp);
        //     System.debug('List Error: ' + e.getMessage());
        //     System.debug('Error on Line: ' + e.getLineNumber());
        // } catch (DMLException e) {
        //     System.debug('DML Error: ' + e.getMessage());
        //     System.debug('Error on Line: ' + e.getLineNumber());
        //     Database.rollback(sp);
        //     //throw new DmlException(e.getMessage());
        //     //think about specific exceptions to catch
        // } catch (Exception e) {
        //     System.debug('Exception type: ' + e.getTypeName());
        //     System.debug('Exception Message: ' + e.getMessage());
        //     System.debug('Exception Line: ' + e.getLineNumber());
        //     Database.rollback(sp);
        // }
    }



    // If using Trigger Handler framework: ////////////

    // public override void afterUpdate() {

    //     List<User> ownerIds = [
    //         SELECT  Id, monthlyOppCounter__c, UserRole.Name
    //         FROM User
    //         WHERE Id IN (
    //             SELECT ownerId
    //             FROM Opportunity
    //             WHERE Id IN :Trigger.new
    //             )
    //             AND UserRole.Name LIKE '%Sales%' 
    //         LIMIT 50000
    //     ];

    //     System.debug(ownerIds);

       


    // }

   
}