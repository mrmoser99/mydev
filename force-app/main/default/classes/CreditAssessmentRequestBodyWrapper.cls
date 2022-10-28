/**
* Name: CreditAssessmentRequestBodyWrapper 
* Purpose: This class is used as forming the JSON structure for the Credit Assesment API request.
* It provides request body wrapper for CreditAssesment callout
* 
* 
* */
public with sharing class CreditAssessmentRequestBodyWrapper extends BaseRequestBodyWrapper {
    
    public String businessOwnerVerified = 'false';
    public AdditionalBusinessInformation additionalBusinessInformation;
    
    public class AdditionalBusinessInformation {
        public FoodAndAgriculture foodAndAgriculture;
        public HealthCare healthCare;
    }
    
    
    public class FoodAndAgriculture {
        public Summary summary;
        public List<FarmingDetail> farmingDetails;
        public List<ContractingDetail> contractingDetails;
    }
    
    
    public class Summary {
        public String areaUnit = 'acres';
        public String salesAmountUnit = 'GBP';
        public Decimal areaOwned = 0;
        public Decimal areaRented = 0;
        public Decimal areaTenanted = 0;
        public Decimal farmSubsidy = 0;
        public Decimal fulltime = 0;
        public Decimal parttime = 0;
        public Decimal selfEmployed = 0;       
    }
    
    public class FarmingDetail {
        public String name = 'wheat-and-barley';
        public String unit = 'acres';
        public Integer value = 0;       
    }
    
    
    public class ContractingDetail {
        public String name = 'mowing';
        public String unit = 'acres';
        public Integer value = 0;       
    }
    
    
    public class HealthCare {
        public String businessType = 'string';
        public String businessActivity = 'string';
        public String medicalLicenseNumber = 'string';     
    }
    
    
    public CreditAssessmentRequestBodyWrapper() { }
    
    
    public override void init(Map<String, Object> params) {
        this.additionalBusinessInformation = buildAdditionalBusinessInformation();
    }
    
    
    private AdditionalBusinessInformation buildAdditionalBusinessInformation() {
        AdditionalBusinessInformation additionalBusinessInformation = new AdditionalBusinessInformation();
        additionalBusinessInformation.foodAndAgriculture = buildFoodAndAgriculture();
        additionalBusinessInformation.healthCare = new HealthCare();       

        return additionalBusinessInformation;
    }
    
    
    private FoodAndAgriculture buildFoodAndAgriculture() {
        FoodAndAgriculture foodAndAgriculture = new FoodAndAgriculture();
        foodAndAgriculture.summary = new Summary();
        foodAndAgriculture.farmingDetails = buildFarmingDetails();  
        foodAndAgriculture.contractingDetails = buildContractingDetails();

        return foodAndAgriculture;
    }
    
    
    private List<FarmingDetail> buildFarmingDetails() {
        List<FarmingDetail> farmingDetails = new List<FarmingDetail>{new FarmingDetail()};
            
        return farmingDetails;
    }
    
    
    private List<ContractingDetail> buildContractingDetails() {
        List<ContractingDetail> contractingDetails = new List<ContractingDetail>{new ContractingDetail()};
            
        return contractingDetails;
    }
}