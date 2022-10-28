/**
 * Test class for creating Opportunity test data 
 * Version 1.0
 */
@isTest
public class TestOpportunityBuilder {

    private String name = 'Apple';
    private String type = 'New';
    private String stage = 'Quoting';
    private String subStage = 'Calculation';
    private Integer daysAfterToday = 365;
    private Date closeDate  = Date.today() + daysAfterToday;
    private Id accountId;
    private Id recordTypeId;
    private Id customerId;
    private String currencyIsoCode = 'SEK';
    private Integer amount;
    private Id standardPricebook;

    private Boolean insertRecord = false;

    public TestOpportunityBuilder withRecordType(String recordTypeDeveloperName){
        recordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName).getRecordTypeId();
        return this;
    }

    public TestOpportunityBuilder withName(String name) {
        this.name = name;
        return this;
    }

    public TestOpportunityBuilder withAccount(Id accountId) {
        this.accountId = accountId;
        return this;
    }

    public TestOpportunityBuilder withType(String type) {
        this.type = type;
        return this;
    }

    public TestOpportunityBuilder withStage(String stage) {
        this.stage = stage;
        return this;
    }

    public TestOpportunityBuilder withSubStage(String subStage) {
        this.subStage = subStage;
        return this;
    }

    public TestOpportunityBuilder withCloseDate(Date closeDate) {
		this.closeDate = closeDate;
		return this;
    }
    
    public TestOpportunityBuilder withEndUser(Id customerId) {
		this.customerId = customerId;
		return this;
    }
    
    public TestOpportunityBuilder withCurrencyIsoCode(String currencyIsoCode) {
		this.currencyIsoCode = currencyIsoCode;
		return this;
	}

    public TestOpportunityBuilder withAmount(Integer amount) {
		this.amount = amount;
		return this;
	}

    public TestOpportunityBuilder withStandardPricebook(Id standardPricebook) {
		this.standardPricebook = standardPricebook;
		return this;
	}

    public TestOpportunityBuilder insertRecord(Boolean insertRecord) {
        this.insertRecord = insertRecord;
        return this;
    }

    public Opportunity build(){

        Opportunity testOpportunity = new Opportunity(
            RecordTypeId = this.recordTypeId,
            Name = this.name,
            Type = this.type,
            StageName = this.stage,
            Sub_Stage__c = this.subStage,
            CloseDate = this.closeDate,
            AccountId = this.accountId,
            End_User__c = this.customerId,
            currencyIsoCode = this.currencyIsoCode,
            amount = this.amount,
            pricebook2id = this.standardPricebook
        );

        if(insertRecord) {
            insert testOpportunity;
        }

        return testOpportunity;
    }
}