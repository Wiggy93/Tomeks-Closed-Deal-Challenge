/*  Guh... This shouldn't do everything
    If you want your custom exception cool but typically they're 1-liner classes, they don't have so much logic in them.
    And they're either in their own file or as an "inner class":

        public with sharing class OpportunityTriggerHandler extends TriggerHandler{
            //bla bla bla, variables, methods...
            static void myMethod(Boolean x){
                if(x){
                    throw new OpportunityTriggerHandler.BadDataException('go away!');
                }
            }

            public class BadDataException extents Exception{}
        }
*/
public with sharing class OpportunityTriggerHandlerException extends Exception{

    //Assume 1 user triggering update to opportunity
        // erm... yes, you can assume that. Triggers run for 1 user at a time which you can always see in UserInfo class. Another user would have their own trigger execution, their own debug log?
    //Assume can go into negative Opp Counts if you're a really bad salesperson that month.

    //implements schedulable for 1st month logic to reset all user.dealCounter = 0;
        // this comment has no place here, doesn't help understanding what's going on in here ;)

    public static void oppDealCounter(Set<Id> ownerIds) {

        Savepoint sp = Database.setSavepoint(); // unused, wastes DML for no good reason. no try-catch, no rollback

        AggregateResult[] groupedOpportuniteis = [
            SELECT Count(Id) oppCount, OwnerId ownerId
            FROM Opportunity
            WHERE OwnerId IN :ownerIds // isn't really to spec, where's the UserRole.Name LIKE '%Sales%'
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

        /*  Hm. OK, it works. I'd do it differently as some kind of "user1 => +5, user2 => -3" based on trigger.new
            but it's not wrong per se. Congrats on using IsWon
            Did you do the other bit of reducing another counter on lost deals?

            I'm suprised you didn't get slapped with MIXED_DML exception. Does it work for you because you don't have a Role?

            What's with this backup of commented out code below ;)
        */

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