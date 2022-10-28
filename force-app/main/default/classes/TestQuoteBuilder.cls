/**
 * Test class for creating Quote test data 
 * 
 * Version 1.0
 * 
 */
@isTest
public class TestQuoteBuilder {

    private String name = 'Test Quote';
    private String status = 'Calculation';
    private Id opportunityId;
    private Id applicableOfferId;
    private Id quoteRateId;
    private Decimal financedAmount;
    private String term;
    private Boolean insertRecord = false;
    private String valueTerm;
    private String frequency;
    private String paymentTiming;
    private String valueDownpayment;
    private String pricebook2Id;
    private String insuranceDisplayOptions = '1';

    public TestQuoteBuilder withName(String name) {
        this.name = name;
        return this;
    }

    public TestQuoteBuilder withAmount(Decimal financedAmount) {
        this.financedAmount = financedAmount;
        return this;
    }

    public TestQuoteBuilder withStatus(String status) {
        this.status = status;
        return this;
    }

    public TestQuoteBuilder withOpportunity(Id opportunityId) {
        this.opportunityId = opportunityId;
        return this;
    }

    public TestQuoteBuilder withApplicableOffer(Id applicableOfferId) {
        this.applicableOfferId = applicableOfferId;
        return this;
    }

    public TestQuoteBuilder withQuoteRate(Id quoteRateId) {
        this.quoteRateId = quoteRateId;
        return this;
    }
    
    public TestQuoteBuilder withQuoteTerm(String term) {
        this.term = term;
        return this;
    }

    public TestQuoteBuilder withValueTerm(String valueTerm) {
        this.valueTerm = valueTerm;
        return this;
    }
     public TestQuoteBuilder withInsuranceDisplayOption(String insuranceDisplayOptions) {
        this.insuranceDisplayOptions = insuranceDisplayOptions;
        return this;
    }

    public TestQuoteBuilder withFrequency(String frequency) {
        this.frequency = frequency;
        return this;
    }

    public TestQuoteBuilder withPaymentTiming(String paymentTiming) {
        this.paymentTiming = paymentTiming;
        return this;
    }

    public TestQuoteBuilder withValueDownpayment(String valueDownpayment) {
        this.valueDownpayment = valueDownpayment;
        return this;
    }

    public TestQuoteBuilder withPricebook2Id(String pricebook2Id) {
        this.pricebook2Id = pricebook2Id;
        return this;
    }

    public TestQuoteBuilder insertRecord(Boolean insertRecord) {
        this.insertRecord = insertRecord;
        return this;
    }

    public Quote build() {
        Quote testQuote = new Quote(
            OpportunityId = this.opportunityId,
            Name = this.name,
            Status = this.status,
            Applicable_Offers__c = this.applicableOfferId,
            Quote_Rate__c = this.quoteRateId,
            Financed_Amount__c = this.financedAmount,
            Term__c = this.term,
            Value_term__c = this.valueTerm,
            Frequency__c = this.frequency,
            Payment_Timing__c = paymentTiming,
            Value_downpayment__c = valueDownpayment,
            Pricebook2Id = pricebook2Id,
            Insurance_Display_Options__c = insuranceDisplayOptions
        );

        if(insertRecord) {
            insert testQuote;
        }

        return testQuote;
    }
}