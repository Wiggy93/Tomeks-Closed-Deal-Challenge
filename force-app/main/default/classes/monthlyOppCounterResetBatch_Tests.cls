@isTest 
public with sharing class monthlyOppCounterResetBatch_Tests {
   @TestSetup
    static void makeData(){
    
        UserRole salesRole  = new UserRole(Name = 'Sales guy');
        insert salesRole;
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard Platform User'];
        System.debug(p);

        List<User> userList = new List<User>();
        for (Integer i = 0; i < 3; i++) {
            User user1 = new User(
                Alias = 'standt', 
                Email='standarduser@testorg.com', 
                TimeZoneSidKey='America/Los_Angeles', 
                UserName='standarduser@testorg.com2222' + i,
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
            SELECT Id, FirstName, UserRole.Name, ProfileId
            FROM User
            WHERE Profile.Name = 'System Administrator'
        ];

        System.debug(admin);

        System.runAs(admin){
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
        }
    }
}