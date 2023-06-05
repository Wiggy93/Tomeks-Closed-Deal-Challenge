public with sharing class OpportunityTriggerHandlerException extends Exception{

    //Assume 1 user triggering update to opportunity
    //Assume can go into negative Opp Counts if you're a really bad salesperson that month.

    //implements schedulable for 1st month logic to reset all user.dealCounter = 0;

    public static void oppDealCounter(List<Opportunity> oppTriggers) {

        Savepoint sp = Database.setSavepoint();
        
        List<Opportunity> oppList = (List<Opportunity>) oppTriggers;
        
        List<User> ownerIds = [
            SELECT  Id, monthlyOppCounter__c, UserRole.Name
            FROM User
            WHERE Id IN (
                SELECT ownerId
                FROM Opportunity
                WHERE Id IN :oppList
                )
                AND UserRole.Name LIKE '%Sales%' 
                LIMIT 1
                ];
                
                System.debug(ownerIds);
        
        // Appropriate Location of try statement???
        try {
            if ( ownerIds[0].UserRoleId == null) {
                ownerIds[0].UserRoleId.addError('Please have a Role assigned to your user account.');
            }
            if ( ownerIds.size() > 0) {
                User u                 = new User(Id = ownerIds[0].Id);
                u.UserRoleId           = ownerIds[0].UserRoleId;
                u.monthlyOppCounter__c = ownerIds[0].monthlyOppCounter__c;
                System.debug(u);
                
                if (u.monthlyOppCounter__c == null) {
                    u.monthlyOppCounter__c = 0;
                }

                for (Opportunity o : oppList) {
                    if ( o.StageName == 'Closed Won' ) {
                        u.monthlyOppCounter__c++;
                    } else if ( o.StageName == 'Closed Lost' ) {
                        u.monthlyOppCounter__c--;
                    }
                }
                System.debug(u);
                update u;
            } 
       
        } catch (System.ListException e) {
            Database.rollback(sp);
            System.debug('List Error: ' + e.getMessage());
            System.debug('Error on Line: ' + e.getLineNumber());
        } catch (DMLException e) {
            System.debug('DML Error: ' + e.getMessage());
            System.debug('Error on Line: ' + e.getLineNumber());
            Database.rollback(sp);
            //throw new DmlException(e.getMessage());
            //think about specific exceptions to catch
        } catch (Exception e) {
            System.debug('Exception type: ' + e.getTypeName());
            System.debug('Exception Message: ' + e.getMessage());
            System.debug('Exception Line: ' + e.getLineNumber());
            Database.rollback(sp);
        }
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