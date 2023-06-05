@isTest
public with sharing class NightlyOppLostBatch_Tests {
    //tests
    //x/updates single record
    //x/updates 200 records
    //x/Doesn't affect Closed Won opps
    //Doesn't change those with CloseDate in past or future
    
    @isTest 
    static void updatesSingle() {
        Opportunity opp = new Opportunity(
            Name        = 'Test',
            StageName   = 'Prospecting',
            CloseDate   = Date.today()
        );
        insert opp;

        Opportunity opp2 = new Opportunity(
            Name        = 'Test',
            StageName   = 'Closed Won',
            CloseDate   = Date.today()
        );
        insert opp2;

        Test.startTest();
            Database.executeBatch(new NightlyOppLostBatch());
        Test.stopTest();

        Opportunity postUpdate = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Id = :opp.Id
            ];

        System.assertEquals('Closed Lost', postUpdate.StageName, 'StageName should have updated from prospecting to Closed Lost');

        Opportunity postUpdate2 = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Id = :opp2.Id
        ];

        System.assertEquals('Closed Won', postUpdate2.StageName, 'Batch method shouldn\'t change closed won opportunities');
    }

    @isTest
    static void updatesBulk() {
        List<Opportunity> oppList= new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            Opportunity o = new Opportunity(
                Name        = 'Test' + i,
                CloseDate   = Date.today()
            );
            if (i < 100) {
                o.StageName = 'Prospecting';
            } else {
                o.StageName = 'Closed Won';
            }
            oppList.add(o);
        }
        insert oppList;

        System.assertEquals(200, [SELECT Id FROM Opportunity WHERE Id IN :oppList].size(), 'Check all opportinuties inserted');

        Test.startTest();
            Database.executeBatch(new NightlyOppLostBatch());
        Test.stopTest();

        List<Opportunity> postUpdatesChangeBulk = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Id IN :oppList AND StageName = 'Closed Lost'
            ];

        List<Opportunity> postUpdatesChange = [
            SELECT Id
            FROM Opportunity
            WHERE Id IN :oppList AND StageName = 'Prospecting'
        ];

        List<Opportunity> postUpdatesSameBulk = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Id IN :oppList AND StageName = 'Closed Won'
            ];

        System.assertEquals(100, postUpdatesChangeBulk.size(), 'Confirm 100 Prospecting opps converted to Closed Lost');
        System.assertEquals(0, postUpdatesChange.size(), 'Confirm 100 Prospecting opps converted to Closed Lost, none remaining');
        System.assertEquals(100, postUpdatesSameBulk.size(), 'Confirm 100 Closed won opps remained closed won');
    }

    @isTest
    static void closeDateTest() {
        Opportunity opp = new Opportunity(
            Name        = 'Test',
            StageName   = 'Prospecting',
            CloseDate   = Date.today() -3
        );
        insert opp;

        Opportunity opp2 = new Opportunity(
            Name        = 'Test',
            StageName   = 'Perception Analysis',
            CloseDate   = Date.today() +3
        );
        insert opp2;

        List<Opportunity> insertedOpp = [
            SELECT CloseDate
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        List<Opportunity> insertedOpp2 = [
            SELECT CloseDate
            FROM Opportunity
            WHERE Id = :opp2.Id
        ];

        //testing setup of test
        // System.assertEquals(Date.today() - 3, insertedOpp[0].CloseDate, 'Correctly inserted a past date');
        // System.assertEquals(Date.today() + 3, insertedOpp2[0].CloseDate, 'Correctly inserted a future date');

        Test.startTest();
            Database.executeBatch(new NightlyOppLostBatch());
        Test.stopTest();

        List<Opportunity> postUpdate1 = [
            SELECT Id, CloseDate, StageName
            FROM Opportunity
            WHERE Id = :opp.Id
        ];

        List<Opportunity> postUpdate2 = [
            SELECT Id, CloseDate, StageName
            FROM Opportunity
            WHERE Id = :opp2.Id
        ];

        System.assertEquals(1, postUpdate1.size(), 'testing single opportunity');
        System.assertEquals(1, postUpdate2.size(), 'testing single opportunity');
        System.assertEquals('Prospecting', postUpdate1[0].StageName, 'Scheduled class  hasn\'t affected StageName as past date');
        System.assertEquals('Perception Analysis', postUpdate2[0].StageName, 'Scheduled class Hasn\'t affected StageName as future date');
    }
}