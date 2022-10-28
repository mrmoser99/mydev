/**
 * Class implements REST webservice for getting information about RV values by the applicable offer id
 * Example: https://host/services/apexrest/assetmodels/00102000006TaohAAC
 * 
 * @author Elena Sokolova
 * @author Ravisha Chugani
 * 
 * @date    v.1 2021-04-07
 *          v.2 2021-04-19
 *          v.3 2021-05-21
 *          v.4 2021-08-24  Elena Sokolova  Insurance data has been added
 *          v.5 2021-09-10  Elena Sokolova  Set RV = 0 for non applicable RV products 
 */
@RestResource(urlMapping='/assetmodels/*')
global with sharing class AssetModelWebService {

    /**
     * Method is a custom REST API call.
     * It’s annotated with @HttpGet and is invoked for a GET request.
     * Sets blob response (contains array with RV data for each product)
     */
    @HttpGet
    global static void getAssetModelData() {

        // Get access to the request
        RestRequest request = RestContext.request;
        // Represents an object used to pass data from an Apex RESTful Web service method to an HTTP response
        RestResponse response = RestContext.response;

        Id applicableOfferId;

        try {
            // get the applicable offer Id from the end of the URL
            applicableOfferId = (Id) request.requestURI.substring(request.requestURI.lastIndexOf('/') + 1);
        } catch (Exception ex) {
            response.statusCode = 500;
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(ex, Constants.INTEGRATION_ERRORLOG_RECORDTYPE, null, true); 
            return;
        }

        // get applicable offer 
        Applicable_Offer__c applicableOffer ;//= new WoSSelector().getApplicableOffer(applicableOfferId);

        // check if an applicable offer Id is empty or an offer with this Id doesn't exists
        if (!String.isEmpty(applicableOfferId)) {
            applicableOffer = new WoSSelector().getApplicableOffer(applicableOfferId);
            if(applicableOffer == null){
                response.statusCode = 404;
                return;
            }
        }else{
            response.statusCode = 404;
            return;
        }

        Id assetProgramId = applicableOffer.Offer__r.Program__r.Asset_Program__c;
        Id partnerId = applicableOffer.Account__c;
        String rvType = applicableOffer.Offer__r.RV_Type__c; 

        // get list of Asset_Program_Detail__c (contains info about products, RV categories and priorities (RV Matrix lookup). 
        // list contains just Asset_Program_Detail__c with Is_RV_Applicable__c = TRUE
        List<Asset_Program_Detail__c> assetProgramDetails = new WoSSelector().getAssetProgramDetails(assetProgramId);

        // get list of junctions between Offer and RV Matrix. it is used to check Asset Program Detail priority 
        //List<Applicable_RV__c> applicableRVs = applicableOffer.Offer__r.IS_RV_Applicable__c ? new WoSSelector().getApplicableRVs(applicableOffer.Offer__c) : new List<Applicable_RV__c>();
		List<Applicable_RV__c> applicableRVs = rvType == Constants.DLL_3RDPARTY_RV 
            								  ? new WoSSelector().getApplicableRVs(applicableOffer.Offer__c) 
            								  : new List<Applicable_RV__c>();
        
        // get id of each available RV Matrix for Offer
        Set<Id> RVMatrixIds = getRVMatrixIds(applicableRVs);

        // get list of wrapper class witch contains info about Asset Program Detail (stores product info) 
        // with appropriate to the Offer RV Matrix and Category
        List<AssetModelItemWrapper> assetModelWrappers = getAssetProgramDetailsWrappers(assetProgramDetails, RVMatrixIds, partnerId,rvType);

        if (assetmodelWrappers.isEmpty()) {
            response.statusCode = 404;
            return;
        }

        // get map of RV_Matrix_Line_Item__c with Category, RV value, Duration by RV Matrix Id
        Map<Id, List<RV_Matrix_Line_Item__c>> RVMatrixLineItems = getRVMatrixLineItems(RVMatrixIds);

        List<Data> data = getListDataForEachProduct(assetModelWrappers, RVMatrixLineItems,rvType);

        if (data.isEmpty()) {
            response.statusCode = 404;
            return;
        }

        response.responseBody = Blob.valueOf(JSON.serialize(new AssetModelData(data), true).replace('default_s', 'default').replace('group_s', 'group').replace('group_2', 'group'));
        response.statusCode = 200;
    }

    public static Set<Id> getRVMatrixIds(List<Applicable_RV__c> applicableRVs) {
        Set<Id> RVMatrixIds = new Set<Id>();

        for (Applicable_RV__c applicableRVItem : applicableRVs) {
            RVMatrixIds.add(applicableRVItem.RV_Matrix__c);
        }

        return RVMatrixIds;
    }

    /**
     * Method checks the priority sequentially starting with the first one. Priority is nothing but RV MAtrix Id.
     * If the matrix Id is contained in the RVMatrixIds list (ids of applicable matrixes for Offer),
     * then AssetModelItemWrapper instance is created and added to the returned list.
     *
     * Asset hard, asset soft and Installation will be part of Asset as it has RV but licence, softcost will be
     * part of softcost as Is_RV_Applicable__c = False.
     * 
     * @return List<AssetModelItemWrapper> contains info about Asset Program Detail (stores product info) 
     * with appropriate to the Offer RV Matrix and Category
     */
    public static List<AssetModelItemWrapper> getAssetProgramDetailsWrappers(List<Asset_Program_Detail__c> assetProgramDetails, Set<Id> RVMatrixIds, Id partnerId,String rvType) {
        List<AssetModelItemWrapper> assetModelWrappers = new List<AssetModelItemWrapper>();
        Set<Id> insuranceIds = getInsuranceIds(assetProgramDetails);
        Map<Id,Insurance__c> insuranceById = new Map<Id,Insurance__c>(new WoSSelector().getInsuranceById(insuranceIds, partnerId));

        for (Asset_Program_Detail__c assetProgramDetailItem : assetProgramDetails) {
            if(rvType == Constants.DLL_3RDPARTY_RV){
                if (assetProgramDetailItem.Product__r.Family == Constants.SOFT_COST_PRODUCT_TYPE || assetProgramDetailItem.Is_RV_Applicable__c == false) {
                    assetModelWrappers.add(new AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), null, null));
                } else {
                    if (RVMatrixIds.contains(assetProgramDetailItem.RV_Priority_1__c)) {
                        assetModelWrappers.add(new AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), assetProgramDetailItem.RV_Priority_1__c, assetProgramDetailItem.RV_Category_1__c));
                    } else if (RVMatrixIds.contains(assetProgramDetailItem.RV_Priority_2__c)) {
                        assetModelWrappers.add(new AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), assetProgramDetailItem.RV_Priority_2__c, assetProgramDetailItem.RV_Category_2__c));
                    } else if (RVMatrixIds.contains(assetProgramDetailItem.RV_Priority_3__c)) {
                        assetModelWrappers.add(new AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), assetProgramDetailItem.RV_Priority_3__c, assetProgramDetailItem.RV_Category_3__c));
                    } else if (RVMatrixIds.contains(assetProgramDetailItem.RV_Priority_4__c)) {
                        assetModelWrappers.add(new AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), assetProgramDetailItem.RV_Priority_4__c, assetProgramDetailItem.RV_Category_4__c));
                    } else if (RVMatrixIds.contains(assetProgramDetailItem.RV_Priority_5__c)) {
                        assetModelWrappers.add(new AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), assetProgramDetailItem.RV_Priority_5__c, assetProgramDetailItem.RV_Category_5__c));
                    } else {
                        assetModelWrappers.add(new AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), null, null));
                    }
                }
            }
            else if(rvType == Constants.PURCHASE_OPTION_RV){
                if (assetProgramDetailItem.Default_Purchase_Option__c !=null && (assetProgramDetailItem.Product__r.Family == Constants.ASSET_HARD_PRODUCT_TYPE || assetProgramDetailItem.Product__r.Family == Constants.ASSET_SOFT_PRODUCT_TYPE)) {
                    assetModelWrappers.add(new AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), Double.valueOf(assetProgramDetailItem.Default_Purchase_Option__c),
                                                                     Double.valueOf(assetProgramDetailItem.Min_Purchase_Option__c), Double.valueOf(assetProgramDetailItem.Max_Purchase_Option__c))); //TODO:: need to check null value in min max and response if null in purchaseoption
                } else { 
                    assetModelWrappers.add(new AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), null, null, null));
                }
            }else{//TODO:::need to check for if Offer enabled for NONE
                 assetModelWrappers.add(new AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), null, null));
            }
            
        }

        return assetModelWrappers;
    }

    public static Map<Id, List<RV_Matrix_Line_Item__c>> getRVMatrixLineItems(Set<Id> RVMatrixIds) {
        Map<Id, List<RV_Matrix_Line_Item__c>> RVMatrixLineItems = new Map<Id, List<RV_Matrix_Line_Item__c>>();

        for (RV_Matrix_Line_Item__c RVMatrixLineItem : new WoSSelector().getRVMarginLineItemsByRVMatrixIds(RVMatrixIds)) 
            {
                if (RVMatrixLineItems.get(RVMatrixLineItem.RV_Matrix__c) == null) {
                    RVMatrixLineItems.put(RVMatrixLineItem.RV_Matrix__c, new List<RV_Matrix_Line_Item__c>{RVMatrixLineItem});
                } else {
                    RVMatrixLineItems.get(RVMatrixLineItem.RV_Matrix__c).add(RVMatrixLineItem);
                }
            }

        return RVMatrixLineItems;
    }

    /**
     * Method iterates list of AssetModelItemWrapper objects and create one instance of Data object
     * for each Product. This object contains info about product id and name, category and RV values and durations for this category.
     * 
     * @return List<Data> which is part of the response
     */
    Public static List<Data> getListDataForEachProduct(List<AssetModelItemWrapper> assetProgramDetailWrappers,  Map<Id,List<RV_Matrix_Line_Item__c>> RVMatrixLineItems, String rvType) {
        List<Data> data = new List<Data>();

        for (AssetModelItemWrapper assetProgramWrapper : assetProgramDetailWrappers) {
            String productId = assetProgramWrapper.assetProgramDetail.Product__c;
            String productName = assetProgramWrapper.assetProgramDetail.Product__r.Name;
            String RVMatrixId = assetProgramWrapper.RVMatrixId; //
            String assetProgramDetailId = assetProgramWrapper.assetProgramDetail.Id;
            String categoryName = assetProgramWrapper.categoryName; //
            String productType = assetProgramWrapper.assetProgramDetail.Product__r.Family;
            String productBrand = assetProgramWrapper.assetProgramDetail.Product__r.Brand__c;
            String insuranceId = assetProgramWrapper.insuranceInfo?.Id;

            List<Cashflow> cashflows = new List<Cashflow>();

            if(rvType == Constants.PURCHASE_OPTION_RV){  
                if(assetProgramWrapper.defaultRV != null){
                    List<Group_s> groups = new List<Group_s>(); 
                    List<Lookup> lookups = new List<Lookup>(); 
                    lookups.add(
                        new Lookup(
                            //new Inputs(Integer.valueOf(RVMatrixLineItem.Duration__r.Term_Value__c), null),
                            new Outputs(assetProgramWrapper.defaultRV, assetProgramWrapper.minRV, assetProgramWrapper.maxRV,Constants.SALE_PRICE, true)
                        )  
                    );
                    
                    groups.add(new Group_s(assetProgramDetailId , 'residual', lookups, true, 'upper'));
                    cashflows.add(new Cashflow(groups));
                }
                else {
                    List<Group_s> groups = new List<Group_s>();
                    List<Lookup> lookups = new List<Lookup>();
                    
                    lookups.add(
                        new Lookup(
                            new Inputs(200, null),
                            new Outputs(0, true)
                        )
                    );
                    
                    groups.add(new Group_s(assetProgramDetailId, 'residual', lookups, true, 'upper'));
                    cashflows.add(new Cashflow(groups));
                }
                
                
            }else{
                if (categoryName != null) {
                    List<Group_s> groups = new List<Group_s>();
                    
                    // get list of all RV Matrix Line Item for particular product
                    List<RV_Matrix_Line_Item__c> RVMatrixLineItemsForProduct = RVMatrixLineItems.get(RVMatrixId);
                    List<Lookup> lookups = new List<Lookup>();
                    
                    for (RV_Matrix_Line_Item__c RVMatrixLineItem : RVMatrixLineItemsForProduct) {
                        // get RV Value and Duration just for appropriate Category
                        if (RVMatrixLineItem.RV_Category__c == categoryName) {
                            lookups.add(
                                new Lookup(
                                    new Inputs(Integer.valueOf(RVMatrixLineItem.Duration__r.Term_Value__c), null),
                                    new Outputs(Double.valueOf(RVMatrixLineItem.RV_Value__c), true)
                                )
                            );
                        }   
                    }
                    
                    groups.add(new Group_s(assetProgramDetailId + RVMatrixId, 'residual', lookups, true, 'upper'));
                    cashflows.add(new Cashflow(groups));
                } else {
                    List<Group_s> groups = new List<Group_s>();
                    List<Lookup> lookups = new List<Lookup>();
                    
                    lookups.add(
                        new Lookup(
                            new Inputs(200, null),
                            new Outputs(0, true)
                        )
                    );
                    
                    groups.add(new Group_s(assetProgramDetailId, 'residual', lookups, true, 'upper'));
                    cashflows.add(new Cashflow(groups));
                }
            }
            
            if (insuranceId != null) {
                List<Group_s> groups = new List<Group_s>();
                List<Lookup> lookups = new List<Lookup>();
                
                Double cost =  assetProgramWrapper.insuranceInfo.Cost__c != null ? assetProgramWrapper.insuranceInfo.Cost__c : 0;
                Double minMargin =  assetProgramWrapper.insuranceInfo.Minimum_Margin__c != null ? assetProgramWrapper.insuranceInfo.Minimum_Margin__c : 0;
                Double maxMargin =  assetProgramWrapper.insuranceInfo.Maximum_Margin__c != null ? assetProgramWrapper.insuranceInfo.Maximum_Margin__c : 0;
                

                // get all Insurance Line Item for particular product by insurance Id
                for (Insurance_Line_Item__c insuranceItem : assetProgramWrapper.insuranceInfo.Insurance_Line_Item__r) {
                    
                    lookups.add(
                        new Lookup(
                            new Inputs(null,Double.valueOf(insuranceItem.Financial_Amount__c)),
                           	// new Outputs(Double.valueOf(insuranceItem.Premium_cost__c))
                           	//new Outputs(Double.valueOf(insuranceItem.Premium_cost__c), cost + minMargin, cost + maxMargin, Constants.SALE_PRICE, null)
                        	//changes made to workaround Quick Calc Error
                            new Outputs(Double.valueOf(insuranceItem.Premium_cost__c), cost + minMargin, cost + maxMargin, Constants.LIST_PRICE, null,Constants.LIST_PRICE)
                        )
                    );
                }

                groups.add(new Group_s(assetProgramDetailId + insuranceId, 'insurance', lookups, true, 'upper'));
                cashflows.add(new Cashflow(groups));
            }
            
            data.add(new Data(productId, productName, productBrand, productType, cashflows));
        }

        return data;
    }

    private static Set<Id> getInsuranceIds(List<Asset_Program_Detail__c> assetProgramDetails) {
        Set<Id> insuranceIds = new Set<Id>();
        
        for (Asset_Program_Detail__c assetDetail : assetProgramDetails) {
            insuranceIds.add(assetDetail.Insurance__c);
        }

        return insuranceIds;
    }

    /**
     * Inner class-selector
     */
    public without sharing class WoSSelector {

        public Applicable_Offer__c getApplicableOffer(Id applicableOfferId) {
            List<Applicable_Offer__c> applicableOffers = 
                [
                    SELECT  Offer__c, Account__c,
                   // Offer__r.IS_RV_Applicable__c,
                    Offer__r.Program__r.Asset_Program__c, 
                    Offer__r.RV_Type__c                    
                    FROM    Applicable_Offer__c 
                    WHERE   Id =: applicableOfferId
                ];
    
            return (applicableOffers.isEmpty()) ? null : applicableOffers[0];
        }

        public List<Asset_Program_Detail__c> getAssetProgramDetails(Id assetProgramId) {
            return [
                SELECT  Id, Is_RV_Applicable__c, Product__c, Product__r.Name, Product__r.Family, Product__r.Brand__c, 
                        RV_Category_1__c, RV_Category_2__c, RV_Category_3__c, RV_Category_4__c, RV_Category_5__c, 
                        RV_Priority_1__c, RV_Priority_2__c, RV_Priority_3__c, RV_Priority_4__c, RV_Priority_5__c,
                         Insurance__c, ITAD_Product__r.Name,
               			Default_Purchase_Option__c,Max_Purchase_Option__c,Min_Purchase_Option__c
                FROM    Asset_Program_Detail__c
                WHERE   Asset_Program__c =: assetProgramId 
                AND     (Product__r.Family = :Constants.SOFT_COST_PRODUCT_TYPE OR Product__r.Family = :Constants.ASSET_HARD_PRODUCT_TYPE 
                         OR Product__r.Family = :Constants.ASSET_SOFT_PRODUCT_TYPE OR Product__r.Family = :Constants.INSTALLATION_PRODUCT_TYPE
                         OR Product__r.Family = :Constants.LICENCE_PRODUCT_TYPE)
            ];
        }

        public List<Applicable_RV__c> getApplicableRVs(Id offerId) {
            return [
                SELECT  RV_Matrix__c, RV_Matrix__r.Name
                FROM    Applicable_RV__c
                WHERE   Offer__c =: offerId
            ];
        }

        public List<RV_Matrix_Line_Item__c> getRVMarginLineItemsByRVMatrixIds(Set<Id> RVMatrixIds) {
            return [
                SELECT  Id, RV_Matrix__c, RV_Matrix__r.Guarantor__r.Name, RV_Category__c, RV_Value__c, Duration__r.Term_Value__c
                FROM    RV_Matrix_Line_Item__c  
                WHERE   RV_Matrix__c IN :RVMatrixIds ORDER BY Duration__r.Term_Value__c ASC nulls last 
            ];
        }

        private List<Insurance__c> getInsuranceById(Set<Id> insuranceIds, Id partnerId) {
            return [
                SELECT  Id, Name,Cost__c,Minimum_Margin__c,Maximum_Margin__c, (SELECT Financial_Amount__c, Premium_cost__c FROM Insurance_Line_Item__r WHERE Partner__c = :partnerId)
                FROM    Insurance__c
                WHERE   Id IN :insuranceIds
            ];
        }
    }

    /**
     * Wrapper class for response body
     */
    public class AssetModelData {
        public List<Data> data;

        public AssetModelData(List<Data> data) {
            this.data = data;
        }
    }

    public class Data {
        public String id;
        public String name;
        public String assetBrandName;
        public String assetTypeName;
        public List<Cashflow> cashflows;

        public Data(String id, String name, String assetBrandName, String assetTypeName, List<Cashflow> cashflows) {
            this.id = id;
            this.name = name;
            this.assetBrandName = assetBrandName;
            this.assetTypeName = assetTypeName;
            this.cashflows = cashflows;
        }
    }

    public class Cashflow {
        public List<Group_s> group_s;

        public Cashflow(List<Group_s> group_s) {
            this.group_s = group_s;
        }
    }

    public class Group_s {
        public String cashflowType;
        public String id;
        public String interpolation;
        public List<Lookup> lookups;
        public Boolean excludeFromAPR;

        public Group_s(String id, String cashflowType, List<Lookup> lookups, Boolean excludeFromAPR, String interpolation) {
            this.id = id;
            this.lookups = lookups;
            this.cashflowType = cashflowType;
            this.excludeFromAPR = excludeFromAPR;
            this.interpolation = interpolation;
        }
    }

    public class Lookup {
        public Inputs inputs;
        public Outputs outputs;

        public Lookup(Inputs inputs, Outputs outputs) {
            this.inputs = inputs;
            this.outputs = outputs;
        }
        
         public Lookup( Outputs outputs) {
            //this.inputs = inputs;
            this.outputs = outputs;
        }
    }

    public class Inputs {
        public Integer numberOfMonths;
		public Double financeAmount; 
        /*
         * public Double salePrice;
        	public Inputs(Integer numberOfMonths, Double salePrice) {
                this.numberOfMonths = numberOfMonths;
                this.salePrice = salePrice;
        }
		*/
        
       // changes made to workaround Quick Calc Error
        public Inputs(Integer numberOfMonths, Double financeAmount) {
            this.numberOfMonths = numberOfMonths;
            this.financeAmount = financeAmount;
        }
    }

    public class Outputs {
        public Boolean annual;
        public Double default_s;
        public String defaultPercentageOf = Constants.SALE_PRICE;
        public Double min;
        public Double max;
        public String minPercentageOf;
        public String maxPercentageOf;

        public Outputs(Double default_s, Boolean annual) {
            this.default_s = default_s;
            this.annual = annual;
        }

        public Outputs(Double default_s) {
            this.default_s = default_s;
        }
        
        public Outputs(Double default_s, Double min, Double max, String percentageOf, Boolean annual) {
            this.default_s = default_s;
            this.min = min;
            this.max = max;
            this.minPercentageOf = percentageOf;
            this.maxPercentageOf = percentageOf;
            if(annual != null){
                this.annual = annual;
            }
            
        }
        //changes made to workaround Quick Calc Error                     
        public Outputs(Double default_s, Double min, Double max, String percentageOf, Boolean annual, String defaultPercentageOf) {
            this.default_s = default_s;
            this.min = min;
            this.max = max;
            this.minPercentageOf = percentageOf;
            this.maxPercentageOf = percentageOf;
            this.defaultPercentageOf = defaultPercentageOf;
            if(annual != null){
                this.annual = annual;
            }
            
        }
    }

    /**
     * Wrapper class contains info about Asset Program Detail (stores product info) 
     * with appropriate to the Offer RV Matrix and Category
     */
    public class AssetModelItemWrapper {
        public Asset_Program_Detail__c assetProgramDetail;
        public Insurance__c insuranceInfo;
        public Id RVMatrixId;
        public String categoryName;
        
        public Double defaultRV;
        public Double minRV;
        public Double maxRV;

        public AssetModelItemWrapper(Asset_Program_Detail__c assetProgramDetail, Insurance__c insuranceInfo, Id RVMatrixId, String categoryName) {
            this.assetProgramDetail = assetProgramDetail;
            this.insuranceInfo = insuranceInfo;
            this.RVMatrixId = RVMatrixId;
            this.categoryName = categoryName; 
        }
        
         public AssetModelItemWrapper(Asset_Program_Detail__c assetProgramDetail, Insurance__c insuranceInfo, Double defaultRV, Double minRV, Double maxRV) {
            this.assetProgramDetail = assetProgramDetail;
            this.insuranceInfo = insuranceInfo;
            this.defaultRV = defaultRV;
            this.minRV = minRV;
            this.maxRV = maxRV;
        }
    }
}