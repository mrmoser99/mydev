/**
 * Test class for creating Program test data 
 * 
 * Version 1.0
 * 
 */
@isTest
public class TestProgramBuilder {
    
    private String name = 'Tractor seasonal program';
    private String currencyIsoCode = 'USD';
    private String assetProgram;
    private String region;
    private String businessUnit; 
    private Decimal allowedMinimumDeposit; 
    private Decimal allowedMaximumDeposit; 

    private Boolean insertRecord = false;

    public TestProgramBuilder withName(String name) {
        this.name = name;
        return this;
    }
    
     public TestProgramBuilder withRegion(String region) {
        this.region = region;
        return this;
    }
    
     public TestProgramBuilder withBusinessUnit(String businessUnit) {
        this.businessUnit = businessUnit;
        return this;
    }
    
    public TestProgramBuilder withcurrencyIsoCode(String currencyIsoCode) {
        this.currencyIsoCode = currencyIsoCode;
        return this;
    }

    public TestProgramBuilder insertRecord(Boolean insertRecord) {
        this.insertRecord = insertRecord;
        return this;
    }

    public TestProgramBuilder withAssetProgram(String assetProgramId) {
        this.assetProgram = assetProgramId;
        return this;
    }

    public TestProgramBuilder withAllowedMinimumDeposit(Decimal allowedMinimumDeposit) {
        this.allowedMinimumDeposit = allowedMinimumDeposit;
        return this;
    }

    public TestProgramBuilder withAllowedMaximumDeposit(Decimal allowedMaximumDeposit) {
        this.allowedMaximumDeposit = allowedMaximumDeposit;
        return this;
    }
    
    public Program__c build() {
        Program__c testProgram = new Program__c(
            Name = this.name,
            CurrencyIsoCode = this.currencyIsoCode,
            Asset_Program__c = this.assetProgram,
            Business_Unit__c = this.businessUnit,
            Region__c = this.region,
            Allowed_Minimum_Deposit__c = this.allowedMinimumDeposit,
            Allowed_Maximum_Deposit__c = this.allowedMaximumDeposit
        );

        if(insertRecord) {
            insert testProgram;
        }

        return testProgram;
    }
}