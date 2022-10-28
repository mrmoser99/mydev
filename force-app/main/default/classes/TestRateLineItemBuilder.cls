/**
 * Test class for creating RateLineItem test data 
 * 
 * Version 1.0
 * 
 */
@isTest
public class TestRateLineItemBuilder {

    Id rateId;
    Id termId;
    Decimal rateValue = 0.5;

    private Boolean insertRecord = false;

    public TestRateLineItemBuilder withRate(Id rateId) {
        this.rateId = rateId;
        return this;
    }

    public TestRateLineItemBuilder withTerm(Id termId) {
        this.termId = termId;
        return this;
    }

    public TestRateLineItemBuilder withValue(Decimal rateValue) {
        this.rateValue = rateValue;
        return this;
    }

    public TestRateLineItemBuilder insertRecord(Boolean insertRecord) {
        this.insertRecord = insertRecord;
        return this;
    }

    public Rate_Line_Item__c build() {
        Rate_Line_Item__c testRateLineItem = new Rate_Line_Item__c(
            Rate__c = this.rateId,
            Term__c = this.termId,
            Rate_Value__c = this.rateValue
        );

        if(insertRecord) {
            insert testRateLineItem;
        }

        return testRateLineItem;
    }
}