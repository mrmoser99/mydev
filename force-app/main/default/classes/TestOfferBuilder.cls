/**
 * Test class for creating Offer test data 
 * 
 * Version 1.0
 * 
 */
@isTest
public class TestOfferBuilder {
    
    private String name = 'Tractor Offer';
    private String currencyIsoCode = 'USD';
    private String type = 'Standard';
    private String selectableBaseRate = 'Both';
    private Integer daysAfterToday = 365;
    private Date validFrom = Date.today();
    private Date validUntil = Date.today().addDays(daysAfterToday);
    private Id programId;
    private Id fixedRateId;
    private Id variableRateId;
    private String rvType = Constants.DLL_3RDPARTY_RV;
    private boolean isITADApplicable = false;
    private Boolean insertRecord = false;
    private Id coreFinancialProduct;
    private String extensionCode = 'A';
    private String selectableAgreementTerm;
    
     public TestOfferBuilder withSelectableAgreementTerm(String  selectableAgreementTerm){
         this.selectableAgreementTerm = selectableAgreementTerm;
        return this;
    }
    
    public TestOfferBuilder withcoreFinancialProduct(Id  coreFinancialProduct){
         this.coreFinancialProduct = coreFinancialProduct;
        return this;
    }
    
     public TestOfferBuilder withcurrencyIsoCode(String  currencyIsoCode){
         this.currencyIsoCode = currencyIsoCode;
        return this;
    }
    public TestOfferBuilder withExtensionCode(String  extensionCode){
         this.extensionCode = extensionCode;
        return this;
    }
    /*public TestOfferBuilder withisRVApplicable(Boolean  isRVApplicable){
         this.isRVApplicable = isRVApplicable;
        return this;
    }*/

    public TestOfferBuilder withisRVApplicable(String  rvType){
        this.rvType = rvType;
       return this;
   }
    
    public TestOfferBuilder withisITADApplicable(Boolean  isITADApplicable){
         this.isITADApplicable = isITADApplicable;
        return this;
    }
    
    public TestOfferBuilder withName(String name) {
        this.name = name;
        return this;
    }

    public TestOfferBuilder withValidFromDate(Date validFrom) {
        this.validFrom = validFrom;
        return this;
    }

    public TestOfferBuilder withValidUntilDate(Date validUntil) {
        this.validUntil = validUntil;
        return this;
    }

    public TestOfferBuilder withProgram(Id programId) {
        this.programId = programId;
        return this;
    }

    public TestOfferBuilder withFixedRate(Id fixedRateId) {
        this.fixedRateId = fixedRateId;
        return this;
    }

    public TestOfferBuilder withVariableRate(Id variableRateId) {
        this.variableRateId = variableRateId;
        return this;
    }
    
    public TestOfferBuilder insertRecord(Boolean insertRecord) {
        this.insertRecord = insertRecord;
        return this;
    }

    public Offer__c build() {
        Offer__c testOffer = new Offer__c(
            Name = this.name,
            Program__c = this.programId,
            Valid_From__c = this.validFrom,
            Valid_Until__c = this.validUntil,
            CurrencyIsoCode = this.currencyIsoCode,
            Offer_Type__c = this.type,
            Selectable_Base_Rate__c = this.selectableBaseRate,
            Base_Rate_Fixed__c = this.fixedRateId,
            Base_Rate_Variable__c = this.variableRateId,
            RV_Type__c = this.rvType,
            IS_ITAD_Applicable__c = this.isITADApplicable,
            Core_Financial_Product__c = this.coreFinancialProduct,
            Extension_Code__c = extensionCode,
            Selectable_Agreement_Term__c = selectableAgreementTerm
        );

        if(insertRecord) {
            insert testOffer;
        }

        return testOffer;
    }
}