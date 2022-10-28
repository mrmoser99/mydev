/**
 * Test class for UpdateQuoteStatusBatch
 * 
 * Version 1.0
 * 
 */
@isTest
public class UpdateQuoteStatusBatchTest {
    @testSetup
    static void setupTestData() {
        TestDataFactory dataFactory = TestDataFactory.getInstance();
        dataFactory .buildRegion('Sweden', 'SE')
                    .buildTerm('Months',30)
                    .buildMarginMatrix('Test Matrix')
                    .buildVendorAccount('Tractor')
                    .buildPartnerDealOpportunity()
                    .buildRate('Test Rate', 'Fixed')
                    .buildProgram('Tractor seasonal program')
                    .buildOffer('Tractor Offer')
                    .buildApplicableOffer('Test')
                    .buildQuote('Test Quote', 50000);
                    
                    
    }

    @isTest static void offerAndRateAreValid_QuoteStatusRemainsInCalculation() {

        Test.startTest();
        Database.executeBatch(new UpdateQuoteStatusBatch());
        Test.stopTest();

        Quote quoteToTest = [SELECT Status FROM Quote LIMIT 1];
        System.assertEquals('Calculation', quoteToTest.Status);
    }

    @isTest static void offerIsExpiredRateIsValid_QuoteStatusUpdatedToCalculationExpired() {

        Offer__c offer = [SELECT Valid_Until__c FROM Offer__c LIMIT 1];
        offer.Valid_Until__c = Date.today();
        update offer;

        Test.startTest();
        Database.executeBatch(new UpdateQuoteStatusBatch());
        Test.stopTest();

        Quote quoteToTest = [SELECT Status FROM Quote LIMIT 1];
        System.assertEquals('Calculation Expired', quoteToTest.Status);    
    }

    @isTest static void offerIsValidRateIsExpired_QuoteStatusUpdatedToCalculationExpired() {

        Rate__c rate = [SELECT Valid_Until__c FROM Rate__c LIMIT 1];
        rate.Valid_Until__c = Date.today();
        update rate;

        Test.startTest();
        Database.executeBatch(new UpdateQuoteStatusBatch());
        Test.stopTest();

        Quote quoteToTest = [SELECT Status FROM Quote LIMIT 1];
        System.assertEquals('Calculation Expired', quoteToTest.Status);    
    }
}