/**
 * This class is used as forming the JSON structure for the calculation API request
 * 
 * Version 1.0 @author Anujit Das
 * Version 1.1 @author Elena Sokolova @date 2021-05-21 (maintenance section has been added)
 */
  /**
     * This list of attributes of the class is based on request body swagger definition
     * https://msc-web-ihub-dev.azurewebsites.net/?spec=test_swagger-programs-v2.json
     * see: /{programId}/financialproducts/{financialProductId}/calculations request
     */
public with sharing class CalculationRequestBodyWrapper extends BaseRequestBodyWrapper {


    static final string USD_CURRENCY = Constants.USD_CURRENCY; 
    public String calculate; // payments, finance-amount
    
    public List<CalculationAsset> assets;
    public List<Maintenance> maintenance;   
    static set<string> itadProdNameSet = new set<String>();
    static map<string,integer> itadProdNameToTotalQuantityMap = new map<string,integer>();
    static map<string,Asset_Program_Detail__c> productNameToAssetDetailsMap = new map<string,Asset_Program_Detail__c>();   
    
    public CalculationFinanceStructure financeStructure;

    public CalculationRequestBodyWrapper() {}

    public override void init(Map<String, Object> params) {

        this.calculate = (String) params.get('paymentOrFinance');
        this.financeStructure = prepareCalculationFinanceStructure(params);

        if (params.containsKey('assets')) {
            this.assets = prepareCalculationAssets(params);
        }     
        if(params.get('maintenance') != null){
            this.maintenance = prepareCalculationMaintenance(params);
        }
        
    }

    public class CalculationFinanceStructure {

        public Integer numberOfMonths;
        public String paymentFrequency;
        public String paymentTiming;
        public CalculationFinance finance;
    }

    public class CalculationFinance {

        public Double financeAmount;
        public CalculationPayments payments;
        public CalculationNetDeposit netDeposit;
        public CalculationRates rates;
    }
    
    public class CalculationNetDeposit {

        public double downPayment;
    }
    
    public class CalculationRates {

        public boolean variableNominalInterestRate;
        
    }
    
    public class CalculationPayments {

        public List<CalculationConsolidatedPayment> consolidated;
    }

    public class CalculationConsolidatedPayment {

        public Date startDate;
        public Double amount;
        public String type = 'regular';
        public Integer numberOfPayments;
    }

    public class CalculationFinanceNetDeposit {

        public Integer downPayment = 1;
    }

    public class CalculationAsset {

        public CalculationAssetModelIdentifier modelIdentifier;
        public Integer quantity = 0;
        public Double salePrice = null;
        public Double listPrice = null;
        public ResidualValue residualValue;
        public List<CalculationAssetInsurance> insurances;
       
    }
    
    public class CalculationAssetModelIdentifier {

        public String modelName;

        public CalculationAssetModelIdentifier(String modelName) {
            this.modelName = modelName;
        }
    }

    public class ResidualValue {

        public double value;

        public ResidualValue(double value) {
            this.value = value;
        }
    }
    
    public class CalculationAssetInsurance {        
        public double amount;
		public String id; 
        
        public CalculationAssetInsurance(double amount) {           
            this.amount = amount;
        }
        
        public CalculationAssetInsurance(String insuranceId) {           
            this.id = insuranceId;
        }
    }

    public class Maintenance {
        public String id;
        public Double amount;

        public Maintenance(String id, Double amount) {
            this.id = id;
            this.amount = amount;
        }
    }

    
    /**
    Name: prepareCalculationFinanceStructure
    Purpose: prepare the finance structure object/array in the json
     */
    private CalculationFinanceStructure prepareCalculationFinanceStructure(Map<String, Object> params) {

        CalculationFinanceStructure cfs = new CalculationFinanceStructure();
        cfs.numberOfMonths = (Integer) params.get('terms');
        cfs.paymentFrequency = (String) params.get('paymentFrequency');
        cfs.paymentTiming = (String) params.get('paymentTiming');
        cfs.finance = prepareCalculationFinance(params);

        return cfs;
    }

     /**
    Name: prepareCalculationFinance
    Purpose: calculate the finance amount in the json
     */
    private CalculationFinance prepareCalculationFinance(Map<String, Object> params) {

        CalculationFinance cf = new CalculationFinance();

        String paymentOfFinance = (String) params.get('paymentOrFinance');
        if (paymentOfFinance == Constants.CALCULATE_PAYMENTS) {      
            cf.financeAmount = params.containsKey('amount') ? (Double) params.get('amount') : 0;        
        }

        if (paymentOfFinance != Constants.CALCULATE_PAYMENTS) {
            cf.payments = prepareCalculationPayments(params);
        }
        cf.netDeposit = prepareCalculationDownpayment(params);
		cf.rates = prepareCalculationRates(params); 
        return cf;
    }
    
    /**
    Name: prepareCalculationDownpayment
    Purpose: calculate the netdeposit in the json
     */
     @testvisible
    private CalculationNetDeposit prepareCalculationDownpayment(Map<String, Object> params) {

        CalculationNetDeposit nd = new CalculationNetDeposit ();
       
        if(params.containsKey('downPayment')){
            nd.downPayment = Double.valueOf((String) params.get('downPayment'));
        }

        return nd;
    }
    
    /**
    Name: prepareCalculationRates
    Purpose: calculate the rate in the json
     */
     @testvisible
    private CalculationRates prepareCalculationRates(Map<String, Object> params) {

        CalculationRates rate = new CalculationRates();
        if(params.containsKey('interest')){
            rate.variableNominalInterestRate = String.valueof(params.get('interest')) == Constants.VARIABLE_RATE_TYPE ? true : false;
        }
        return rate;
    }
     /**
    Name: prepareCalculationPayments
    Purpose: calculate the payment amount in the json
     */
    @testvisible
    private CalculationPayments prepareCalculationPayments(Map<String, Object> params) {

        CalculationPayments cp = new CalculationPayments();
        cp.consolidated = prepareCalculationConsolidatedPayments(params);

        return cp;
    }

     /**
    Name: prepareCalculationConsolidatedPayments
    Purpose: prepare the consolidated payment structure in the json
     */
    private List<CalculationConsolidatedPayment> prepareCalculationConsolidatedPayments(Map<String, Object> params) {

        CalculationConsolidatedPayment ccp = new CalculationConsolidatedPayment();
        ccp.startDate = Date.today();
        ccp.amount = (Double) params.get('amount');
        String paymentFrequency = (String) params.get('paymentFrequency');
        Integer months = 0;

        if(paymentFrequency == Constants.MONTHLY_PAYMENT_FREQUENCY){
            months = 1;
        }
        else if(paymentFrequency == Constants.QUARTERLY_PAYMENT_FREQUENCY ){
            months = 3;
        }
        else if(paymentFrequency == Constants.SEMI_ANNUALLY_PAYMENT_FREQUENCY ){
            months = 6;
        }
        else if(paymentFrequency == Constants.ANNUALLY_PAYMENT_FREQUENCY ){
            months = 12;
        }
        else{
            
        }
        ccp.numberOfPayments = (Integer) params.get('terms') / months;

        return new List<CalculationConsolidatedPayment>{ccp};
    }

    /**
    Name: prepareCalculationAssets
    Purpose: prepare the asset structure in the json
     */
    private List<CalculationAsset> prepareCalculationAssets(Map<String, Object> params) {

        String paymentOfFinance = (String) params.get('paymentOrFinance');
        List<CalculationAsset> calculationAssets = new List<CalculationAsset>();      
        List<Map<String, Object>> assets = (List<Map<String, Object>>) params.get('assets');
        Map<string,integer> productNameToQuantityMap = new Map<string,integer>();
        CalculationAsset newCalculationAsset;
        
        for (Map<String, Object> asset : assets) {
            newCalculationAsset = new CalculationAsset();
            newCalculationAsset.quantity = (Integer) asset.get('quantity');
            if (paymentOfFinance == Constants.CALCULATE_PAYMENTS) {
                newCalculationAsset.salePrice = (Double) asset.get('salePrice');
                
                //send Adjustable RV and Insurance to Lacs and check response its with in boundries or not
                if(asset.get('residualValue') != null){
                    newCalculationAsset.residualValue = new ResidualValue((double) asset.get('residualValue'));
                }
                
                if(asset.get('insuranceAmt') != null) 
                {
                    newCalculationAsset.insurances = new List<CalculationAssetInsurance>{new CalculationAssetInsurance(
                         (Double) asset.get('insuranceAmt'))};
                }   
                
            } else {
                newCalculationAsset.listPrice = (Double) asset.get('salePrice');
                newCalculationAsset.residualValue = new ResidualValue(
                    (double) asset.get('residualValue'));
                newCalculationAsset.insurances = new List<CalculationAssetInsurance>{new CalculationAssetInsurance(
                     (String) asset.get('insuranceId'))};
            }
            newCalculationAsset.modelIdentifier = new CalculationAssetModelIdentifier(
                (String) asset.get('modelName')
            );
            
            calculationAssets.add(newCalculationAsset);
            string prodName = (String) asset.get('modelName');
            productNameToQuantityMap.put(prodName.toLowerCase(),(Integer) asset.get('quantity'));
        }

        return calculationAssets;
    }
    
    //pass the program id, applicable offer id and selected product with quantity from ui
    /**
    *Name: findItadApplicableInOffer
    *Purpose: find the ITAD prices for the selected products
    */
    public static List<FeesWrapperClass> findItadApplicableInOffer(id programId, id applicableOfferId,map<string,integer> productNameToQuantityMap, string itadCategory){
        
        map<string,double> itadCategoryPriceMap = new map<string,double>();
        
        List<Applicable_Offer__c> applicableOfferList = new WosClass().getApplicableOfferList(applicableOfferId);
        List<FeesWrapperClass> feesWrCls = new List<FeesWrapperClass>();
        
        //if ITAD is not applicable in offer record, then return
        if(applicableOfferList.size() > 0 && !applicableOfferList[0]?.Offer__r.Is_ITAD_Applicable__c){
            return null;
        }else if(applicableOfferList.size() > 0 && applicableOfferList[0]?.Offer__r.Is_ITAD_Applicable__c){
            set<id> itadProductIdSet =  new WosClass().getItadProducts(applicableOfferList[0].Offer__r.Program__r.Asset_Program__c,productNameToQuantityMap);
            if(itadProductIdSet != NULL && itadProductIdSet.size() > 0){
                list<PricebookEntry> priceBookEntryList =  new WosClass().itadProdsCostDetails(itadProductIdSet,itadCategory);
                double conversionRate =  new WosClass().getCurrencyConversionRate();
                map<string,integer> itadProdIdToTotalQuantityMap = findTotalItadProductQuantity(productNameToQuantityMap);
                //calling different methods for calcualtion of ITAD prices depending on the ITAD level selected from UI
                switch on itadCategory {
                   when 'Onsite Packaging' {
                       itadCategoryPriceMap = calculateItadValueforOnsitePackaging(itadProdIdToTotalQuantityMap,priceBookEntryList,conversionRate);
                   }
                   when 'Reversed Logistics' {
                       itadCategoryPriceMap = calculateItadValueforReversedLog(itadProdIdToTotalQuantityMap,priceBookEntryList,conversionRate);                     
                   } 
                   when 'Data Wiping' {
                       itadCategoryPriceMap = calculateItadValueforDataWiping(itadProdIdToTotalQuantityMap,priceBookEntryList,conversionRate);
                   }                
                }
                feesWrCls = createItadRequest(itadCategoryPriceMap);                
                //find itad price per product wise     
                getItadPricePerNonItadProduct(itadCategoryPriceMap,productNameToQuantityMap,itadProdIdToTotalQuantityMap);            
            }          
        }  
        return feesWrCls;
    }
    
    /**
    Name: createItadRequest
    Purpose: Forming the ITAD JSON response structure
     */
    private static List<FeesWrapperClass> createItadRequest(map<string,double> itadCategoryPriceMap){
        
        List<FeesWrapperClass> feesWrapperClassLst = new List<FeesWrapperClass>();

        for(string eachItad : itadCategoryPriceMap.keyset()){
            FeesWrapperClass feesWr = new FeesWrapperClass();
            feesWr.id = eachItad ;
            feesWr.amount = itadCategoryPriceMap.get(eachItad);
            feesWr.quantity = (!itadProdNameToTotalQuantityMap.isEmpty() && itadProdNameToTotalQuantityMap.containsKey(eachItad)) ? itadProdNameToTotalQuantityMap.get(eachItad) : 0;
            feesWrapperClassLst.add(feesWr);
        }
        return feesWrapperClassLst;
         
    }
    
    //find ITAD price per product wise
    private static void getItadPricePerNonItadProduct(map<string,double> itadCategoryPriceMap,map<string,integer> productNameToQuantityMap,map<string,integer> itadProdIdToTotalQuantityMap){
        
        map<String, Double> nonItadProductToITADCostMap = new  map<String, Double>();
        
        for(string eachProdName : productNameToAssetDetailsMap.keyset()){
            double pricePerQuant = 0.0; 
            double pricePerProduct = 0.0;
            string itadProductName = productNameToAssetDetailsMap.get(eachProdName).ITAD_Product__r.Name.toLowerCase();
            if(itadProdNameSet.contains(itadProductName) && productNameToQuantityMap != null && productNameToQuantityMap.containsKey(eachProdName)){
                pricePerQuant = itadCategoryPriceMap.get(itadProductName) / itadProdIdToTotalQuantityMap.get(productNameToAssetDetailsMap.get(eachProdName).ITAD_Product__c);
                pricePerProduct = Math.roundToLong(pricePerQuant * productNameToQuantityMap.get(eachProdName.toLowerCase()));              
            }else if(!itadProdNameSet.contains(itadProductName) && productNameToQuantityMap != null && productNameToQuantityMap.containsKey(eachProdName.toLowerCase())){
                pricePerProduct = itadCategoryPriceMap.get(itadProductName);
            }
            nonItadProductToITADCostMap.put(eachProdName,pricePerProduct);
        }
    }

     /**
    Name: findTotalItadProductQuantity
    Purpose: find the product quantity depending on the ITAD product
     */
    private static map<string,integer> findTotalItadProductQuantity(map<string,integer> productNameToQuantityMap){
        
        map<string,integer> itadProdIdToTotalQuantityMap = new map<string,integer>();
          
        for(string eachProdName : productNameToAssetDetailsMap.keyset()){       
            string itadProductId = productNameToAssetDetailsMap.get(eachProdName).ITAD_Product__c ;
            string itadProductName = productNameToAssetDetailsMap.get(eachProdName).ITAD_Product__r.Name.toLowerCase() ;
            integer productQuantity = productNameToQuantityMap.get(eachProdName.toLowerCase());          
           
           if(itadProdIdToTotalQuantityMap != null && itadProdIdToTotalQuantityMap.containsKey(itadProductId)){              
                integer existingProdQuantity = itadProdIdToTotalQuantityMap.get(itadProductId);               
                productQuantity += existingProdQuantity;
                itadProdIdToTotalQuantityMap.put(itadProductId,productQuantity);
                itadProdNameToTotalQuantityMap.put(itadProductName,productQuantity);
                itadProdNameSet.add(productNameToAssetDetailsMap.get(eachProdName).ITAD_Product__r.name.toLowerCase()); //when itad category is same, add to set
            }else{  
                itadProdIdToTotalQuantityMap.put(itadProductId,productQuantity); //map to hold the total number of quantity with respect to ITAD product id
                itadProdNameToTotalQuantityMap.put(itadProductName,productQuantity); //map to hold the total number of quantity with respect to ITAD product name
            }
        }
        return itadProdIdToTotalQuantityMap;
    }
    
    /**
    Name: calculateItadValueforOnsitePackaging
    Purpose: Calculate ITAD price of onsite packaging
     */
    private static map<string,double> calculateItadValueforOnsitePackaging(map<string,integer> itadProdIdToTotalQuantityMap,list<PricebookEntry> priceBookEntryList,double conversionRate){
              
        map<string,double> itadCategoryTotalPriceMap = calculateItadValueforDataWiping(itadProdIdToTotalQuantityMap,priceBookEntryList,conversionRate);
        conversionRate = conversionRate == 0.0 ? 1 : conversionRate;
        
        for(integer i=0;i<priceBookEntryList.size();i++){         
            double itadProdFixedPrice = 0.0;
            double itadProdPrice11_50 = 0.0;
            double itadProdPrice50Plus = 0.0;
            //find fixed price for 1st itad product, as the list has the highest product in the 1st index
            if(i == 0 && itadProdIdToTotalQuantityMap.containsKey(priceBookEntryList[i].Product2Id)){
                //fixed price
                integer itadProdQuantity = itadProdIdToTotalQuantityMap.get(priceBookEntryList[i].Product2Id); //find wrt itad id
                itadProdFixedPrice = priceBookEntryList[i].Onsite_Packaging_Fixed__c * conversionRate;               
                //find remaining quantity
                integer remainingQuantity = itadProdQuantity - 10;
                if(remainingQuantity > 0 && remainingQuantity <= 40){                 
                    itadProdPrice11_50 = remainingQuantity * priceBookEntryList[i].Onsite_Packaging_Unit_Cost_11_50__c * conversionRate;
                }else if(remainingQuantity > 0 && remainingQuantity > 40){
                    itadProdPrice11_50 = 40 * priceBookEntryList[i].Onsite_Packaging_Unit_Cost_11_50__c * conversionRate;  
                    remainingQuantity = remainingQuantity - 40;
                    itadProdPrice50Plus = remainingQuantity * priceBookEntryList[i].Onsite_Packaging_Unit_Cost_51__c * conversionRate;                    
                }                            
                double itadDwPrice = itadCategoryTotalPriceMap.get(priceBookEntryList[i].Product2.Name.toLowerCase());
                itadCategoryTotalPriceMap.put(priceBookEntryList[i].Product2.Name.toLowerCase(),Math.roundToLong(itadDwPrice+itadProdFixedPrice+itadProdPrice11_50+itadProdPrice50Plus));    
                
            }else if(i > 0 && itadProdIdToTotalQuantityMap.containsKey(priceBookEntryList[i].Product2Id)){
                integer itadProdQuantity = itadProdIdToTotalQuantityMap.get(priceBookEntryList[i].Product2Id);
                //find remaining quantity                
                if(itadProdQuantity > 0 && itadProdQuantity <= 50){                 
                    itadProdPrice11_50 = itadProdQuantity * priceBookEntryList[i].Onsite_Packaging_Unit_Cost_11_50__c * conversionRate;
                }else if(itadProdQuantity > 0 && itadProdQuantity > 50){
                    itadProdPrice11_50 = 50 * priceBookEntryList[i].Onsite_Packaging_Unit_Cost_11_50__c * conversionRate; 
                    itadProdQuantity = itadProdQuantity - 50;
                    itadProdPrice50Plus = itadProdQuantity * priceBookEntryList[i].Onsite_Packaging_Unit_Cost_51__c * conversionRate;                   
                }
                double itadDwPrice = itadCategoryTotalPriceMap.get(priceBookEntryList[i].Product2.Name.toLowerCase());
                itadCategoryTotalPriceMap.put(priceBookEntryList[i].Product2.Name.toLowerCase(),Math.roundToLong(itadDwPrice+itadProdPrice11_50+itadProdPrice50Plus));
            }
        }
        return itadCategoryTotalPriceMap;
    }
    
    /**
    Name: calculateItadValueforReversedLog
    Purpose: Calculate ITAD price of reveresed logistics
     */
    private static map<string,double> calculateItadValueforReversedLog(map<string,integer> itadProdIdToTotalQuantityMap,list<PricebookEntry> priceBookEntryList,double conversionRate){
       
        map<string,double> itadCategoryTotalPriceMap = calculateItadValueforDataWiping(itadProdIdToTotalQuantityMap,priceBookEntryList,conversionRate);
       
        conversionRate = conversionRate == 0.0 ? 1 : conversionRate;
        
        for(integer i=0;i<priceBookEntryList.size();i++){         
            double itadProdFixedPrice = 0.0;
            double itadProdPrice11_50 = 0.0;
            double itadProdPrice50Plus = 0.0;
            //find fixed price for 1st itad product, as the list has the highest product in the 1st index
            if(i == 0 && itadProdIdToTotalQuantityMap.containsKey(priceBookEntryList[i].Product2Id)){
                //fixed price
                integer itadProdQuantity = itadProdIdToTotalQuantityMap.get(priceBookEntryList[i].Product2Id); //find wrt itad id
                itadProdFixedPrice = priceBookEntryList[i].Reversed_Logistics_Fixed__c * conversionRate;               
                //find remaining quantity
                integer remainingQuantity = itadProdQuantity - 10;
                if(remainingQuantity > 0 && remainingQuantity <= 40){                 
                    itadProdPrice11_50 = remainingQuantity * priceBookEntryList[i].Reversed_Logistics_Unit_Cost_11_50__c * conversionRate;
                }else if(remainingQuantity > 0 && remainingQuantity > 40){
                    itadProdPrice11_50 = 40 * priceBookEntryList[i].Reversed_Logistics_Unit_Cost_11_50__c * conversionRate;  
                    remainingQuantity = remainingQuantity - 40;
                    itadProdPrice50Plus = remainingQuantity * priceBookEntryList[i].Reversed_Logistics_Unit_Cost_51__c * conversionRate;                    
                }  
                double itadDwPrice = itadCategoryTotalPriceMap.get(priceBookEntryList[i].Product2.Name.toLowerCase());             
                itadCategoryTotalPriceMap.put(priceBookEntryList[i].Product2.Name.toLowerCase(),Math.roundToLong(itadDwPrice+itadProdFixedPrice+itadProdPrice11_50+itadProdPrice50Plus));
            
            }else if(i > 0 && itadProdIdToTotalQuantityMap.containsKey(priceBookEntryList[i].Product2Id)){
                integer itadProdQuantity = itadProdIdToTotalQuantityMap.get(priceBookEntryList[i].Product2Id);
                //find remaining quantity                
                if(itadProdQuantity > 0 && itadProdQuantity <= 50){                 
                    itadProdPrice11_50 = itadProdQuantity * priceBookEntryList[i].Reversed_Logistics_Unit_Cost_11_50__c * conversionRate;
                }else if(itadProdQuantity > 0 && itadProdQuantity > 50){
                    itadProdPrice11_50 = 50 * priceBookEntryList[i].Reversed_Logistics_Unit_Cost_11_50__c * conversionRate; 
                    itadProdQuantity = itadProdQuantity - 50;
                    itadProdPrice50Plus = itadProdQuantity * priceBookEntryList[i].Reversed_Logistics_Unit_Cost_51__c * conversionRate;                   
                }
                double itadDwPrice = itadCategoryTotalPriceMap.get(priceBookEntryList[i].Product2.Name.toLowerCase());   
                itadCategoryTotalPriceMap.put(priceBookEntryList[i].Product2.Name.toLowerCase(),Math.roundToLong(itadDwPrice+itadProdPrice11_50+itadProdPrice50Plus));
            }
        }
        return itadCategoryTotalPriceMap;
    }
    
    /**
    Name:calculateItadValueforDataWiping
    Purpose: Calculate ITAD price of Data Wiping
     */
    public static map<string,double> calculateItadValueforDataWiping(map<string,integer> itadProdIdToTotalQuantityMap, list<PricebookEntry> priceBookEntryList, Double conversionRate){
       
        map<string,double> itadCategoryTotalPriceMapforDW = new map<String,double>();
        conversionRate = conversionRate == 0.0 ? 1 : conversionRate;
        
        for(integer i=0; i<priceBookEntryList.size(); i++){       
           double itadProdFixedPrice = 0.00 ;
           if(itadProdIdToTotalQuantityMap.containsKey(priceBookEntryList[i].Product2Id)){
                integer itadProdQuantity = itadProdIdToTotalQuantityMap.get(priceBookEntryList[i].Product2Id);
                itadProdFixedPrice = Math.roundToLong(priceBookEntryList[i].Data_Wiping_Fixed_Cost_Per_Unit__c * itadProdQuantity * conversionRate);              
            }
            itadCategoryTotalPriceMapforDW.put(priceBookEntryList[i].Product2.Name.toLowerCase(),itadProdFixedPrice); 
          } 
          
          return itadCategoryTotalPriceMapforDW;
    }
    
    public without sharing class WosClass{
        /**
        Name:getApplicableOfferList
        Purpose: SOQL to get the asset program from applicable offer
        */
        private List<Applicable_Offer__c> getApplicableOfferList(Id applicableOfferId){
            
            return [SELECT Offer__c,Offer__r.Program__r.Asset_Program__c,
                    Offer__r.Is_ITAD_Applicable__c 
                    FROM Applicable_Offer__c 
                    WHERE id =: applicableOfferId LIMIT 1];
        }
    
        /**
        Name:getItadProducts
        Purpose: SOQL to get the asset program details
        */
        private set<id> getItadProducts(id assetProgramId,map<string,integer> productNameToQuantityMap){
            
            set<id> itadProductIdSet = new set<id>();
            
            try{
                for(Asset_Program_Detail__c eachAsset : [SELECT Id,Product__r.Name,
                                                                ITAD_Product__c ,
                                                                ITAD_Product__r.name 
                                                                FROM Asset_Program_Detail__c 
                                                                WHERE Asset_Program__c=: assetProgramId 
                                                                AND 
                                                                Product__r.Name IN: productNameToQuantityMap.keyset() 
                                                                AND 
                                                                ITAD_Product__r.Family =: Constants.ITAD_PRODUCT_TYPE]){
                
                    itadProductIdSet.add(eachAsset.ITAD_Product__c); //add the itad products id into a set
                    productNameToAssetDetailsMap.put(eachAsset.Product__r.Name.toLowerCase(),eachAsset);
                }         
            }catch(Exception e) {
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, assetProgramId, true); 
            }     
        
        return itadProductIdSet;                                                              
        }
        
        /**
        Name:getCurrencyConversionRate
        Purpose: SOQL to get the conversion rate: 1USD to SEK
        */
        private double getCurrencyConversionRate(){
            
            double conversion_rate = 0.0;
            
            try{
                DatedConversionRate rate = [SELECT Id, isoCode, Conversionrate, nextStartDate 
                                        FROM DatedConversionRate
                                        WHERE isoCode =: label.Current_Currency  
                                        ORDER BY NextStartDate DESC limit 1];
            
                conversion_rate = rate.Conversionrate;
            }catch(Exception e) {
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, '', true);
            }
            
            return conversion_rate;       
        }
        
        /**
        Name:itadProdsCostDetails
        Purpose: SOQL to get the ITAD cost for the selected products
        */
        private list<PricebookEntry> itadProdsCostDetails(set<id> itadProductSet, string itadCategory){
            
            list<PricebookEntry> pbeItadProductsList = new list<PricebookEntry>();
            
            string pbeSoqlString = 'SELECT Id,Product2Id,Product2.Name,Data_Wiping_Fixed_Cost_Per_Unit__c,Onsite_Packaging_Fixed__c, ';
            pbeSoqlString += 'Onsite_Packaging_Unit_Cost_11_50__c,Onsite_Packaging_Unit_Cost_51__c,Reversed_Logistics_Fixed__c,';
            pbeSoqlString += 'Reversed_Logistics_Unit_Cost_11_50__c,Reversed_Logistics_Unit_Cost_51__c ';
            pbeSoqlString += 'FROM PricebookEntry WHERE Product2Id in: itadProductSet AND CurrencyIsoCode =: USD_CURRENCY ';
            
            if(String.isNotBlank(itadCategory) && itadCategory == Constants.REVERSED_LOGISTICS){
                pbeSoqlString += ' ORDER BY Reversed_Logistics_Fixed__c DESC ';
            }else if(String.isNotBlank(itadCategory) && itadCategory == Constants.ONSITE_PACKAGING){
                pbeSoqlString += ' ORDER BY Onsite_Packaging_Fixed__c DESC ';
            }
            
            try{    
                pbeItadProductsList = Database.query(pbeSoqlString); 
            }catch(Exception se) {
                ErrorLogger errorLog = new ErrorLogger();
                errorLog.logException(se, Constants.GENERIC_ERRORLOG_RECORDTYPE, '', true);
            }

            return pbeItadProductsList ;
        }
    }
    
    public class FeesWrapperClass{
        public string id;
        public double amount;
        public integer quantity;
    }

    /**
    Name: prepareCalculationMaintenance
    Purpose: prepare the maintenance structure in the json
    */
    
    private List<Maintenance> prepareCalculationMaintenance(Map<String, Object> params) {
        List<Maintenance> maintenance = new List<Maintenance>();
        List<Map<String, Object>> maintenanceList = (List<Map<String, Object>>) params.get('maintenance');

        for (Map<String, Object> maintenaceItem : maintenanceList) {
            Maintenance newCalculationMaintenance = new Maintenance(
                (String) maintenaceItem.get('id'),
                (Double) maintenaceItem.get('amount')
            );
            maintenance.add(newCalculationMaintenance);
        }

        return maintenance;
    }

}