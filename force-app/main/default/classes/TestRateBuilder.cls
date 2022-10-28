/**
 * Test class for creating Rate test data 
 * 
 * Version 1.0
 * 
 */
@isTest
public class TestRateBuilder {

    private String name = 'Test Rate';
    private String rateType = 'Fixed';
    private Integer daysAfterToday = 365;
    private Date startDate = Date.today();
    private Date validUntil = Date.today().addDays(daysAfterToday);
	private String backofficeReference;
    private Boolean insertRecord = false;

    public TestRateBuilder withName(String name) {
        this.name = name;
        return this;
    }

    public TestRateBuilder withType(String rateType) {
        this.rateType = rateType;
        return this;
    }

    public TestRateBuilder withDate(Date startDate) {
        this.startDate = startDate;
        return this;
    }

    public TestRateBuilder withValidUntilDate(Date validUntil) {
        if(validUntil != null) {
            this.validUntil = validUntil;
        }
        return this;
    }
     public TestRateBuilder withBackofficeReference(String backofficeReference) {
        this.backofficeReference = backofficeReference;
        return this;
    }

    public TestRateBuilder insertRecord(Boolean insertRecord) {
        this.insertRecord = insertRecord;
        return this;
    }

    public Rate__c build() {
        Rate__c testRate = new Rate__c(
            Name = this.name,
            Rate_Type__c = this.rateType,
            Date__c = this.startDate,
            Cost_Of_Funds__c = 1,
            Valid_Until__c = Date.today() + 365,
            Backoffice_Reference__c = backofficeReference
        );

        if(insertRecord) {
            insert testRate;
        }

        return testRate;
    }
}