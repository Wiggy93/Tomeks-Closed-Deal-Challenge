@isTest 
public with sharing class monthlyOppCounterResetBatch_Tests { // Uppercase "Monthly" pls
   @TestSetup
    static void makeData(){
    
        UserRole salesRole  = new UserRole(Name = 'Sales guy');
        insert salesRole;
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard Platform User']; // this will work because we can't delete/rename the standard profiles
        // but generally speaking a more "pro" move would be to assign to List<Profile> profiles = [SELECT...] to avoid "list has no rows for assignment to sobject" and then check if it's isEmpty
        System.debug(p);

        List<User> userList = new List<User>();
        for (Integer i = 0; i < 3; i++) {
            User user1 = new User(
                Alias = 'standt', 
                Email='standarduser@testorg.com', 
                TimeZoneSidKey='America/Los_Angeles', 
                UserName='standarduser@testorg.com2222' + i, // these have to be globally unique, pro players use some Datetime.now().format(), UserInfo.getOrganizationId() and Math.random to generate usernames
                LastName='TestingSales' + i, 
                UserRoleId      = salesRole.Id,
                EmailEncodingKey='UTF-8', 
                LanguageLocaleKey='en_US', 
                LocaleSidKey='en_US', 
                ProfileId = p.Id,
                monthlyOppCounter__c   = 5 
                );
            userList.add(user1);
          }
        insert userList; 
   }

   @isTest
   static void resetCounterBatchTest() {

        User admin = [
            SELECT Id, FirstName, UserRole.Name, ProfileId // whaddyu need FirstName etc for ;) "less is more"
            FROM User
            WHERE Profile.Name = 'System Administrator'
        ];
        // The fact you don't have "LIMIT 1" or WHERE IsActive = true will mean this crashes in any org that has more than 1 admin ;)

        System.debug(admin);

        System.runAs(admin){ // Any special reason this uses runAs?
            Test.startTest();
            Database.executeBatch(new monthlyOppCounterResetBatch());
            Test.stopTest();
            
            // Verify the results
            List<User> updatedUsers = [
                SELECT monthlyOppCounter__c 
                FROM User 
                WHERE Alias = 'standt'
                ];
            System.assertEquals(3, updatedUsers.size(), 'All users should have inserted');
            for (User user : updatedUsers) {
                System.assertEquals(0, user.monthlyOppCounter__c, 'monthlyOppCounter__c field should be reset to 0');
            }

            /* You don't really verify a "before" scenario. Something like this:

                List<User> users = [SELECT monthlyOppCounter__c 
                    FROM User 
                    WHERE Alias = 'standt'];
                for (User u : updatedUsers) {
                    System.assertEquals(5, user.monthlyOppCounter__c, 'monthlyOppCounter__c field should be populated');
                }

                Test.startTes();
                Database.executeBatch(new monthlyOppCounterResetBatch());
                Test.stopTest();
                for (User u : [SELECT monthlyOppCounter__c FROM User WHERE Id IN :users]) {
                    System.assertEquals(0, user.monthlyOppCounter__c, 'monthlyOppCounter__c field should be cleared');
                }

            Ah, and try to avoid writing stuff like "User user", "Account account".
            It can lead to the Dark Side
            Integer Account = 5; // happy debugging suckers
            */
        }
    }
}