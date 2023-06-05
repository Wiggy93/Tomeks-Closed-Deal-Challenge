@isTest
public with sharing class OpportunityTriggerHandler_Tests {

    @TestSetup
    //NB deliberately inserted each role/user as small number/more code to add to list and insert.
    static void makeData(){
        UserRole salesRole  = new UserRole(Name = 'Sales guy');
        insert salesRole;
        UserRole otherRole  = new UserRole(Name = 'Other guy'); 
        insert otherRole;

        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 

        User user1 = new User(
            Alias = 'standt', 
            Email='standarduser@testorg.com', 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com2222',
            LastName='TestingSales', 
            UserRoleId      = salesRole.Id,
            EmailEncodingKey='UTF-8', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = p.Id,
            monthlyOppCounter__c   = 0 
            );
        insert user1;
        
        User user2 = new User(
            Alias               = 'standt', 
            Email               ='standarduser@testorg.com3333', 
            UserName            ='standarduser@testorg.com3333',
            LastName            ='TestingOther', 
            ProfileId           = p.Id, 
            UserRoleId          = otherRole.Id,
            EmailEncodingKey    ='UTF-8', 
            LanguageLocaleKey   ='en_US', 
            LocaleSidKey        ='en_US', 
            TimeZoneSidKey      ='America/Los_Angeles', 
            monthlyOppCounter__c   = 0
            );
        insert user2;
    }

   @isTest
   static void closedWonSalesTest() {
        //Test that user with sales in Role can trigger increase of monthly counter when Inserting with Closed Won stage
        //Test that user with sales in Role can trigger increase of counter ONLY when updating to Closed Won if inserted with another stagename
        User u = [SELECT Id, monthlyOppCounter__c, UserRoleId FROM User WHERE LastName = 'TestingSales'];

        System.runAs(u){
            Test.startTest();
                Opportunity opp1 = new Opportunity(Name = 'TestWon', StageName = 'Closed Won', CloseDate = System.today() + 5);
                insert opp1;

                User insertedU1 = [
                    SELECT monthlyOppCounter__c 
                    FROM User
                    WHERE Id = :u.Id
                ];

                Opportunity opp2 = new Opportunity(Name = 'TestWon', StageName = 'Prospecting', CloseDate = System.today() + 5);
                insert opp2;

                User insertedU2 = [
                    SELECT monthlyOppCounter__c 
                    FROM User
                    WHERE Id = :u.Id
                ];

                opp2.StageName   = 'Closed Won';
                update opp2;

                User updatedU2 = [
                    SELECT monthlyOppCounter__c 
                    FROM User
                    WHERE Id = :u.Id
                ];

            Test.stopTest();

            System.assertEquals(0, u.monthlyOppCounter__c, 'counter starts at 0');
            System.assertEquals(1, insertedU1.monthlyOppCounter__c, 'Should have increased counter from 0 to 1');
            System.assertEquals(1, insertedU2.monthlyOppCounter__c, 'Counter should still be 1, additional opp StageName not Closed...');
            System.assertEquals(2, updatedU2.monthlyOppCounter__c, 'Should have increased counter from 1 to 2');
        }
   }

   @isTest
   //Bulk insert/updates 200 opportunities to test trigger.
   static void bulkInsertTest() {
        User u = [SELECT Id, monthlyOppCounter__c, UserRoleId FROM User WHERE LastName = 'TestingSales'];

        
        System.runAs(u){
            Test.startTest();
                List<Opportunity> oppList1 = new List<Opportunity>();
                List<Opportunity> oppList2 = new List<Opportunity>();

                for (Integer i = 0; i < 200; i++) {
                    Opportunity opp1 = new Opportunity(Name = 'TestWon' + i, StageName = 'Closed Won', CloseDate = System.today() + 5);
                    oppList1.add(opp1);
                }
                insert oppList1;

                User insertedU1 = [
                    SELECT monthlyOppCounter__c 
                    FROM User
                    WHERE Id = :u.Id
                ];

                for (Integer i = 0; i < 200; i++) {
                    Opportunity opp2 = new Opportunity(Name = 'TestWon' + i, StageName = 'Prospecting', CloseDate = System.today() + 5);
                    oppList2.add(opp2);
                }
                insert oppList2;

                User insertedU2 = [
                    SELECT monthlyOppCounter__c 
                    FROM User
                    WHERE Id = :u.Id
                ];

                for (Opportunity o : oppList2 ) {
                    o.StageName   = 'Closed Won';
                }
                update oppList2;

                User updatedU2 = [
                    SELECT monthlyOppCounter__c 
                    FROM User
                    WHERE Id = :u.Id
                ];
            Test.stopTest();

            System.assertEquals(0, u.monthlyOppCounter__c, 'counter starts at 0');
            System.assertEquals(200, insertedU1.monthlyOppCounter__c, '200 Closed Won Opps inserted');
            System.assertEquals(200, insertedU2.monthlyOppCounter__c, 'Counter should still be 200');
            System.assertEquals(400, updatedU2.monthlyOppCounter__c, '200 Opps updated to Closed Won');
        }

   }

   @isTest
   static void closedWonOtherTest() {
       //Test that user without sales in Role cannot trigger increase of monthly counter when Inserting with Closed Won stage
       //Test that user without sales in Role cannot trigger increase of counter when updating to Closed Won.
        User u = [SELECT Id, monthlyOppCounter__c, UserRoleId FROM User WHERE LastName = 'TestingOther'];

        System.runAs(u){
            Test.startTest();
                Opportunity opp1 = new Opportunity(Name = 'TestWon', StageName = 'Closed Won', CloseDate = System.today() + 5);
                insert opp1;

                User insertedU1 = [
                    SELECT monthlyOppCounter__c 
                    FROM User
                    WHERE Id = :u.Id
                ];

                Opportunity opp2 = new Opportunity(Name = 'TestWon', StageName = 'Prospecting', CloseDate = System.today() + 5);
                insert opp2;

                User insertedU2 = [
                    SELECT monthlyOppCounter__c 
                    FROM User
                    WHERE Id = :u.Id
                ];

                opp2.StageName   = 'Closed Won';
                update opp2;

                User updatedU2 = [
                    SELECT monthlyOppCounter__c 
                    FROM User
                    WHERE Id = :u.Id
                ];
            Test.stopTest();

            System.assertEquals(0, u.monthlyOppCounter__c, 'counter starts at 0');
            System.assertEquals(0, insertedU1.monthlyOppCounter__c, 'Should still be 0');
            System.assertEquals(0, insertedU2.monthlyOppCounter__c, 'Counter should still be 0');
            System.assertEquals(0, updatedU2.monthlyOppCounter__c, 'Counter should still be 0');
        }
   }

    @isTest
    static void closedLostSalesTest() {
        //Test that user with sales in Role can trigger increase of monthly counter when Inserting with Closed Won stage
        //Test that user with sales in Role can trigger increase of counter ONLY when updating to Closed Won if inserted with another stagename
        User u = [SELECT Id, monthlyOppCounter__c, UserRoleId FROM User WHERE LastName = 'TestingSales'];

        System.runAs(u){
            Test.startTest();
                Opportunity opp1 = new Opportunity(Name = 'TestWon', StageName = 'Closed Won', CloseDate = System.today() + 5);
                insert opp1;

                User insertedU1 = [
                    SELECT monthlyOppCounter__c 
                    FROM User
                    WHERE Id = :u.Id
                ];

                opp1.StageName  = 'Closed Lost';
                update opp1;

                User updatedU1 = [
                    SELECT monthlyOppCounter__c 
                    FROM User
                    WHERE Id = :u.Id
                ];

                Opportunity opp2 = new Opportunity(Name = 'TestLost', StageName = 'Closed Lost', CloseDate = System.today() + 5);
                insert opp2;

                User insertedU2 = [
                    SELECT monthlyOppCounter__c 
                    FROM User
                    WHERE Id = :u.Id
                ];

            Test.stopTest();

            System.assertEquals(0, u.monthlyOppCounter__c, 'counter starts at 0');
            System.assertEquals(1, insertedU1.monthlyOppCounter__c, 'Should have increased counter from 0 to 1');
            System.assertEquals(0, updatedU1.monthlyOppCounter__c, 'Counter should decrease from 1 to 0 as updated closed lost');
            System.assertEquals(-1, insertedU2.monthlyOppCounter__c, 'Counter should decrease from 0 to -1 as inserted as closed lost');
        }
    }

    @isTest
    static void closedLostOtheTest() {
        //Test that user with sales in Role can trigger increase of monthly counter when Inserting with Closed Won stage
        //Test that user with sales in Role can trigger increase of counter ONLY when updating to Closed Won if inserted with another stagename
        User u = [SELECT Id, monthlyOppCounter__c, UserRoleId FROM User WHERE LastName = 'TestingOther'];

        System.runAs(u){
            Test.startTest();
                Opportunity opp1 = new Opportunity(Name = 'TestWon', StageName = 'Closed Won', CloseDate = System.today() + 5);
                insert opp1;

                User insertedU1 = [
                    SELECT monthlyOppCounter__c 
                    FROM User
                    WHERE Id = :u.Id
                ];

                opp1.StageName  = 'Closed Lost';
                update opp1;

                User updatedU1 = [
                    SELECT monthlyOppCounter__c 
                    FROM User
                    WHERE Id = :u.Id
                ];

                Opportunity opp2 = new Opportunity(Name = 'TestLost', StageName = 'Closed Lost', CloseDate = System.today() + 5);
                insert opp2;

                User insertedU2 = [
                    SELECT monthlyOppCounter__c 
                    FROM User
                    WHERE Id = :u.Id
                ];

            Test.stopTest();

            System.assertEquals(0, u.monthlyOppCounter__c, 'counter starts at 0');
            System.assertEquals(0, insertedU1.monthlyOppCounter__c, 'invalid rolename so no effect');
            System.assertEquals(0, updatedU1.monthlyOppCounter__c, 'invalid rolename so no effect');
            System.assertEquals(0, insertedU2.monthlyOppCounter__c, 'invalid rolename so no effect');
        }
    }

    @isTest
    static void nullCounterTest() {
        User u = [
            SELECT Id, monthlyOppCounter__c
            FROM User
            Where LastName = 'TestingSales'
            ];
            u.monthlyOppCounter__c = null;
            update u;
        
        System.assertEquals(null, u.monthlyOppCounter__c, 'set up correctly with blank counter');


        System.runAs(u) {
            Test.startTest();
            Opportunity opp1 = new Opportunity(Name = 'TestWon', StageName = 'Closed Won', CloseDate = System.today() + 5);
            insert opp1;
            Test.stopTest();

            User u1 = [
                SELECT monthlyOppCounter__c
                FROM User
                WHERE Id = :u.Id
            ];

            System.assertEquals(1, u1.monthlyOppCounter__c, 'converted from null to number, increased by 1');
        }
    }

    @isTest
    static void insertOppErrorTest() {
        User u = [
            SELECT Id, monthlyOppCounter__c
            FROM User
            Where LastName = 'TestingSales'
            ];

            //Missing required Name field.  
            Opportunity opp1 = new Opportunity(StageName = 'Closed Won', CloseDate = System.today() + 5);
			Opportunity opp2 = new Opportunity(Name = 'TestWon', StageName = 'Closed Won', CloseDate = System.today() + 5);
			insert opp2;
            
            System.runAs(u) {
                Test.startTest();
                    try {
                        insert opp1;
                        System.Assert.fail('DmlException expected');
                    } catch (DMLException e) {
                        System.debug('Test debug: ' + e.getMessage());
                        System.assertEquals('REQUIRED_FIELD_MISSING', e.getDmlStatusCode(0), 'Opp missing required Name field');
                    }

					try {
						insert opp2;
						System.Assert.fail('DmlException expected');
					} catch (DMLException e) {
						System.debug('Test debug: ' + e.getMessage());
						System.assertEquals('INVALID_FIELD_FOR_INSERT_UPDATE', e.getDmlStatusCode(0), 'Already inserted opp once, can\'t insert same Id twice');
					}

            Test.stopTest();
        }
    }

	@isTest
	//User with no UserRole Name assigned
	static void noUserRoleTest() {
		Profile p = [SELECT Id FROM Profile WHERE Name='Standard User'];

		User u = new User(
            Alias = 'standt', 
            Email='standarduser@testorg.com', 
            TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@testorg.com4444',
            LastName='noCounter', 
            EmailEncodingKey='UTF-8', 
            LanguageLocaleKey='en_US', 
            LocaleSidKey='en_US', 
            ProfileId = p.Id,
			monthlyOppCounter__c = 0
            );
        insert u;

		Opportunity opp1 = new Opportunity(Name = 'testWon', StageName = 'Closed Won', CloseDate = System.today() + 5);
		
		System.runAs(u) {
			Test.startTest();
				try {
					insert opp1;
					//System.Assert.fail('Exception expected');
				} catch (Exception e) {
					System.debug('Hello123 in Test ' + e.getMessage());
					System.assertEquals('System.ListException', e.getTypeName());
					System.assert(e.getMessage().contains('List Index out of bounds'));
				}
			Test.stopTest();
		}
	}

   /// Error testing scenarios
   //no user associated - is this possible?
   //insert opp already there - can't seem to make this happen?
    //user with no monthlyOppCounter - fixed in handler to 0
    
	
}