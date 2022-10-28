public with sharing class SubmitApplicationHelper{
    

   public static String termValue;
    public static String rvType = '';
    
    public static Quote quote;
    public static List<Asset_Program_Detail__c> assetProgramDetailsList = new List<Asset_Program_Detail__c>();
    public static Set<id> insuranceIdSet = new Set<id>();
    public static List<Applicable_RV__c> applicableRVs =  new List<Applicable_RV__c>();
    public static Set<Id> RVMatrixIds = new Set<Id>();
    public static Map<Id,RV_Matrix__c> RVMatrixMap = new Map<Id,RV_Matrix__c>();
    public static Map<String, RV_Matrix__c> prodNameToRvMatrixMap = new Map<String,RV_Matrix__c>();
    public static String accountTeamMember;
    public static Map<string,double> productNameToPremiumInsuranceMap = new Map<string,double>();
    public static Map<string,double> productNameToRvValueMap = new Map<string,double>();
    public static Map<String, String> backOfficeParamProductsMap = new Map<String, String>();
    public static Map<String, QuoteLineItem> QLIMap = new Map<String, QuoteLineItem>();
    public static Map<String, Object> submitAppParams = new Map<String,Object>();
    public static List<Insurance_Line_Item__c> insuranceLineItemList= new List<Insurance_Line_Item__c>();
    //public static Decimal rentalAmount;
    
    /** 
    *Name: getBodyParameters
    *Purpose: Method to define Body parameters  
    */
    public static Map<String, Object> getBodyParameters (String parameters) {
       
        WosSelector submitAppWosSelector = new WosSelector();        
        
        //Map<String, Object> submitAppParams = (Map<String, Object>) JSON.deserializeUntyped(parameters);
        submitAppParams = (Map<String, Object>) JSON.deserializeUntyped(parameters);
        
        //Final requestBodyParam for submit Application
        Map<String, Object> params = new Map<String, Object>();
        
        String quoteId = (String) submitAppParams.get('quoteId');
        
        //Query Quote along with underlying data 
        quote = submitAppWosSelector.getQuoteDetails(quoteId);
        rvType = quote.Applicable_Offers__r.Offer__r.RV_Type__c;
        //rentalAmount = quote.Rental_Amount__c;
        
        assetProgramDetailsList = submitAppWosSelector.getAssetProgramDetails(quote.Applicable_Offers__r.Offer__r.Program__r.Asset_Program__c);                                                                                                  
        
        //get insuranc id for further querying insurancelineitems
        for(Asset_Program_Detail__c assetProDtl : assetProgramDetailsList){
            insuranceIdSet.add(assetProDtl.Insurance__c);          
        }
        
        //Query insurance along with its line items       
        Map<Id,Insurance__c> insuranceById = new Map<Id,Insurance__c>(submitAppWosSelector.getInsuranceById(insuranceIdSet,quote.AccountId));    
        
        for(Id eachInsuranceId : insuranceById.keySet()){            
            insuranceLineItemList.addAll(insuranceById.get(eachInsuranceId).Insurance_Line_Item__r);
        }
        
        applicableRVs =submitAppWosSelector.getApplicableRVs(quote.Applicable_Offers__r.Offer__c);
       
        for (Applicable_RV__c applicableRVItem : applicableRVs) {
            RVMatrixIds.add(applicableRVItem.RV_Matrix__c);
        }
        
        //Query Rv Matrix along with its line items on offer   
        RVMatrixMap = submitAppWosSelector.getRVMatrixByIds(RVMatrixIds);
        
         //Filter Rv Matrix Map based on product family and RV Priortity from AssetProgramDetails
        prodNameToRvMatrixMap = prodNameToRvMatrix(insuranceById);
        
        accountTeamMember = submitAppWosSelector.getAccountTeamMemberDetails(quote.Account.id);
        
        termValue = QuoteSetupController.getNextHighestTerm(quote.Applicable_Offers__r.Offer__r.Selectable_Agreement_Term__c, (String)submitAppParams.get('qouteTerm'));
        
        productNameToPremiumInsuranceMap = findProductsInsurance(quote.AccountId,(List<Object>) submitAppParams.get('productInfoList'));
        productNameToRvValueMap = findProductsRV(insuranceById,(List<Object>) submitAppParams.get('productInfoList'), Integer.valueOf(termValue));
        
        backOfficeParamProductsMap = getBackOfficeParamAssetDetail();
        
        QLIMap = getQLI(quote.QuoteLineItems);
      
       
        String regionCode = quote.Applicable_Offers__r.Offer__r.Program__r.Region__r.ISO_Code__c;
        String quoteVersion = quote.Name.substringAfterLast('-');
        
        // oppId is needed to update Opportunity record with contract number
        params.put('oppId', quote.OpportunityId != null ? quote.OpportunityId : RESTCalloutHelper.setErrorField('Opportunity Id'));
        params.put('id', quote.Id != null ? quote.Id : RESTCalloutHelper.setErrorField('Quote Id'));
        params.put('contractNumber', (String) submitAppParams.get('oppName') != null ? (String) submitAppParams.get('oppName') + '-' + quoteVersion : RESTCalloutHelper.setErrorField('Opportunity Name'));
        
        params.put('submittedBy',  quote.Owner.firstname +' '+ quote.Owner.lastname);
        params.put('reference', quote.Reference__c !=null ? quote.Reference__c :'');
        
        params.put('owner', accountTeamMember != NULL ? accountTeamMember : '');
        params.put('programCountry', regionCode != null ? regionCode : RESTCalloutHelper.setErrorField('Program Country')); 
        params.put('accountName', quote.Account.Doing_Business_As__c != null ? quote.Account.Doing_Business_As__c : RESTCalloutHelper.setErrorField('Account Name'));
        params.put('businessUnit', quote.Applicable_Offers__r.Offer__r.Program__r.Business_Unit__r.Name != null ? quote.Applicable_Offers__r.Offer__r.Program__r.Business_Unit__r.Name : RESTCalloutHelper.setErrorField('Business Unit'));
        params.put('creationDate', quote.Opportunity.CreatedDate);
        params.put('extensionCode', quote.Applicable_Offers__r.Offer__r.Extension_Code__c != null ? quote.Applicable_Offers__r.Offer__r.Extension_Code__c : RESTCalloutHelper.setErrorField('Extension Code'));
        
        
        
        //Create Parties Node        
        params.put('parties',createPartiesNode());
        
        //Create lessee Node    
        params.put('lessee', createLesseeNode());
        
        //Create FinanceStructure Node    
        params.put('financeStructure', createFinanceStructureNode());   
      
        
        //Create Assests and SoftCosts Node  
        Map<String, Object> assetSoftCostMap =  createAssestsAndSoftCostNode();   
        params.put('assets', (List<Map<String, Object>>)assetSoftCostMap.get('assets'));
        
         //Create Multiple additionalAccountSettings Node 
        List<Map<String, Object>> additionalAccountSettings = new List<Map<String, Object>>();
                                 
        Map<String, Object> additionalAccountSettingsMap = new Map<String, Object>();
        additionalAccountSettingsMap.put('Key', 'Low Touch Flag'); 
        additionalAccountSettingsMap.put('Value',String.Valueof(quote.Account.Low_Touch_Flag__c));
        additionalAccountSettings.add(additionalAccountSettingsMap);
        
        params.put('additionalAccountSettings', additionalAccountSettings);
        
        params.put('softcost', (List<Map<String, Object>>)assetSoftCostMap.get('softcosts')); 
 
        Map<String, Object> contractConditions = new Map<String, Object>();
        contractConditions.put('generalConditionRef', quote.Applicable_Offers__r.Offer__r.General_Terms_and_Conditions__r?.Name);
        //Create Multiple specialConditions        
        if(!quote.Applicable_Special_Terms_and_Conditions__r.isEmpty()){
                List<Map<String, Object>> specialConditions = new List<Map<String, Object>>();
                for(Applicable_Special_Terms_and_Conditions__C eachObj :quote.Applicable_Special_Terms_and_Conditions__r){              
                                          
                    Map<String, Object> specialConditionsMap = new Map<String, Object>();
                    specialConditionsMap.put('condition', eachObj.Special_Terms_and_Conditions__r.Type__c); 
                    specialConditionsMap.put('conditionValue',eachObj.Special_Terms_and_Conditions__r.Body__c != null
                                                     ? eachObj.Special_Terms_and_Conditions__r.Body__c : '');
                    specialConditions.add(specialConditionsMap);                    
                }
                 contractConditions.put('specialConditions', specialConditions);                
            }         
            params.put('contractConditions', contractConditions);
        
        return params;
    }
    
    
    /**
    *Name: getMarginMatrixValue
    *Purpose: This method queries finance amount,term and term value from margin matrix item and margin matrix item value.
    *It returns the final margin matrix item value.
    */
    public static Decimal getMarginMatrixValue(Id marginMatrixId, Integer selectedTermValue, Decimal selectedAmount) {
        
       /* Decimal value = 0;
        Decimal firstAmount = 0;
        Decimal secondAmount = 0;
        Decimal firstTerm = 0;
        Decimal secondTerm = 0;
        List<Margin_Matrix_Item__c> marginMatrixItems = new List<Margin_Matrix_Item__c>();
        
        //Gets value, term value, term and finance amount          
        marginMatrixItems = new WoSSelector().getMarginLineItemsByMargimMatrixId(marginMatrixId);            
        
        for (Margin_Matrix_Item__c marginMatrixItem : marginMatrixItems) {
            value = marginMatrixItem.Value__c;
            
            
            //checks if if the term value is > 0 and then assigs the respective value
            if (secondTerm > 0 && secondTerm < marginMatrixItem.Term__r.Term_Value__c) {
                firstTerm = secondTerm;
            }
            secondTerm = marginMatrixItem.Term__r.Term_Value__c;
            
            firstAmount = secondAmount == null ? 0 : secondAmount;
            secondAmount = marginMatrixItem.Financial_Amount__c;
            
            if (selectedTermValue > firstTerm && selectedTermValue <= secondTerm && selectedAmount > firstAmount && selectedAmount <= secondAmount)
            {
                break;
            }
        }
		 return value;
		*/
        try{
            Margin_Matrix_Item__c marginMatrixItem = new WoSSelector().getMarginLineItemsByMargimMatrixId(marginMatrixId,selectedTermValue,selectedAmount);            
            return marginMatrixItem.Value__c;
        }catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, '', true);            
        }
        
        return 0.0;
    }
    
    /**
    *Name: getExtensionFeeAmount
    *Purpose: to calculate and get extension fee amount  
    *Basic calculation : Rental Amount * Extension Factor Percentage
    */
    private static Decimal getExtensionFeeAmount(Decimal rentalAmount){
       Decimal extensionFeeAmount = 0.0;
       //Decimal extensionPercentage = quote.Account.Extension_Factor_Percentage__c != null ? quote.Account.Extension_Factor_Percentage__c : 0.0;
        if(quote.Account.Extension_Factor_Percentage__c != null){
            extensionFeeAmount = ( rentalAmount /quote.Account.Extension_Factor_Percentage__c  * 100).setScale(2, RoundingMode.CEILING);
            
        } 
        
        return extensionFeeAmount;
    }
    
    /**
    *Name: getBackOfficeParameters
    *Purpose: to get Type and name from backofficeParameter 
    */
    private static  Map<String, String> getBackOfficeParameters(String programId, String accountId) {
        
        Map<String, String> backOfficeParametersMap = new Map<String, String>();
        // list<Program_Partner_Party__c> Authorized_Program_list= new WoSSelector().getProgramPartnerParties(programId,accountId);// club with child
        for (BackOffice_Param__c  param : new WoSSelector().getBOParamsByAuthorizedPrograms(programId,accountId)) {//TODO:: Club parent query in child SELECT Type__c, Value__c,Authorized_Program__r.name,Authorized_Program__r.Program__c,Authorized_Program__r.Dealer__c   FROM BackOffice_Param__c 
            
            backOfficeParametersMap.put(param.Type__c, param.Value__c);
        }
        return backOfficeParametersMap;           
    }
    
    /**
    *Name: getQLI
    *Purpose: to get map for prodNameToQuoteLineItem
    */
    private static  Map<String, QuoteLineItem> getQLI(List<QuoteLineItem> quoteLineItems) {
        
        Map<String, QuoteLineItem> qLIMap = new Map<String, QuoteLineItem>();
        for (QuoteLineItem  param : quoteLineItems) {// club with parent query
            qLIMap.put(param.Product2.Name, param);
        }
        return qLIMap;           
    }
    
    /*
    * Name: prodNameToRvMatrix
    * Purpose: To find the Map prodNameToRvMatrixMap from AssetProgramDetails based on Productfamily and RV Priority
    */
    private static Map<String, RV_Matrix__c> prodNameToRvMatrix(Map<Id,Insurance__C> insuranceById){

        Map<String, RV_Matrix__c> prodNameToRvMatrixMap = new Map<String, RV_Matrix__c> ();
        
        //List<AssetModelWebService.AssetModelItemWrapper> assetProgramDetailWrappers = getAssetProgramDetailsWrappers(assetProgramDetails, RVMatrixIds,insuranceById); 
        List<AssetModelWebService.AssetModelItemWrapper> assetProgramDetailWrappers = getAssetProgramDetailsWrappers(assetProgramDetailsList, RVMatrixMap.keyset(),insuranceById,rvType); 
        for (AssetModelWebService.AssetModelItemWrapper eachAssetModelItemWrapper : assetProgramDetailWrappers) {
            prodNameToRvMatrixMap.put(eachAssetModelItemWrapper.assetProgramDetail.Product__r.Name, RVMatrixMap.get(eachAssetModelItemWrapper.RVMatrixId));
        }
        return prodNameToRvMatrixMap;
    }
    
    
    

    /**
    *Name: getCofAndNominalRate
    *Purpose: to find the exact nominal rate and cof
    */ 
    private static string getCofAndNominalRate(String rateId, String paymentFrequency, decimal margin, String Interest, String Term) {
        
        map<string,string> paymentFrequncyMap = new map<string,string>{'monthly'=>'30','quarterly'=>'90','semi-annually'=>'180','annually'=>'360'}; 
        decimal nominalRate = 0.0;
        decimal cof = 0.0;
        decimal rateValue;
               
        try{
            if(String.isNotBlank(paymentFrequency) && String.isNotBlank(rateId)){
               for(Rate_Line_Item__c eachLine : new WoSSelector().getRateLineItemsByRateId(rateId)){
                   //for fixed rate 
                   if(interest == Constants.FIXED_RATE_TYPE && term == string.valueof(eachLine.Term__r.Term_Value__c) && eachLine.Rate__r.Cost_Of_Funds__c != null && eachLine.Rate_Value__c != null){
                        cof = eachLine.Rate__r.Cost_Of_Funds__c + eachLine.Rate_Value__c;
                        nominalRate = cof + margin;
                     }
                    else if(interest == Constants.VARIABLE_RATE_TYPE && eachLine.Rate__r.Cost_Of_Funds__c != null && eachLine.Rate_Value__c != null && eachLine.Term__r.Term_Value__c == integer.valueof(paymentFrequncyMap.get(paymentFrequency))){
                        //for variable rate
                        cof = eachLine.Rate__r.Cost_Of_Funds__c + eachLine.Rate_Value__c;
                        nominalRate = cof + margin;
                        break;
                        }
                    }
                }           
            }
            
        catch(Exception e){
            ErrorLogger errorLog = new ErrorLogger();
            errorLog.logException(e, Constants.GENERIC_ERRORLOG_RECORDTYPE, null, true);
        }      
        return string.valueof(cof +'-'+nominalRate) ;
    }
    
    /**
    *Name: getBackOfficeParamAssetDetail
    *Purpose: To get back office params according to asset detail program
    */
    private static Map<String, String> getBackOfficeParamAssetDetail() {
        
        Map<String, String> backOfficeParamProductsMap = new Map<String, String>();
        for(Asset_Program_Detail__c param : assetProgramDetailsList) {
            
            backOfficeParamProductsMap.put(param.Product__r.Name,param.BackOffice_Param__r.Value__c);
        }
        return backOfficeParamProductsMap;
        
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
    public static List<AssetModelWebService.AssetModelItemWrapper> getAssetProgramDetailsWrappers(List<Asset_Program_Detail__c> assetProgramDetails, Set<Id> RVMatrixIds,Map<Id,Insurance__C> insuranceById,String rvType) {
        List<AssetModelWebService.AssetModelItemWrapper> assetModelWrappers = new List<AssetModelWebService.AssetModelItemWrapper>();
            
        for (Asset_Program_Detail__c assetProgramDetailItem : assetProgramDetails) {
            //Due to clubing filter creteria for duplicate query, exluding Itad and Maintenance product type from result which is ask of this method
            if(assetProgramDetailItem.Product__r.Family != Constants.ITAD_PRODUCT_TYPE && assetProgramDetailItem.Product__r.Family != Constants.MAINTENANCE_PRODUCT_TYPE){
                if(rvType == Constants.DLL_3RDPARTY_RV){
                    if (assetProgramDetailItem.Product__r.Family == Constants.SOFT_COST_PRODUCT_TYPE || assetProgramDetailItem.Is_RV_Applicable__c == false) {
                        assetModelWrappers.add(new AssetModelWebService.AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), null, null));
                    } else {
                        if (RVMatrixIds.contains(assetProgramDetailItem.RV_Priority_1__c)) {
                            assetModelWrappers.add(new AssetModelWebService.AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), assetProgramDetailItem.RV_Priority_1__c, assetProgramDetailItem.RV_Category_1__c));
                        } else if (RVMatrixIds.contains(assetProgramDetailItem.RV_Priority_2__c)) {
                            assetModelWrappers.add(new AssetModelWebService.AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), assetProgramDetailItem.RV_Priority_2__c, assetProgramDetailItem.RV_Category_2__c));
                        } else if (RVMatrixIds.contains(assetProgramDetailItem.RV_Priority_3__c)) {
                            assetModelWrappers.add(new AssetModelWebService.AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), assetProgramDetailItem.RV_Priority_3__c, assetProgramDetailItem.RV_Category_3__c));
                        } else if (RVMatrixIds.contains(assetProgramDetailItem.RV_Priority_4__c)) {
                            assetModelWrappers.add(new AssetModelWebService.AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), assetProgramDetailItem.RV_Priority_4__c, assetProgramDetailItem.RV_Category_4__c));
                        } else if (RVMatrixIds.contains(assetProgramDetailItem.RV_Priority_5__c)) {
                            assetModelWrappers.add(new AssetModelWebService.AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), assetProgramDetailItem.RV_Priority_5__c, assetProgramDetailItem.RV_Category_5__c));
                        } else {
                            assetModelWrappers.add(new AssetModelWebService.AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), null, null));
                        }
                    } 
                    
                }
                else if(rvType == Constants.PURCHASE_OPTION_RV){
                    if (assetProgramDetailItem.Default_Purchase_Option__c !=null && (assetProgramDetailItem.Product__r.Family == Constants.ASSET_HARD_PRODUCT_TYPE || assetProgramDetailItem.Product__r.Family == Constants.ASSET_SOFT_PRODUCT_TYPE)) {
                        assetModelWrappers.add(new AssetModelWebService.AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), Double.valueOf(assetProgramDetailItem.Default_Purchase_Option__c),
                                                                         Double.valueOf(assetProgramDetailItem.Min_Purchase_Option__c), Double.valueOf(assetProgramDetailItem.Max_Purchase_Option__c))); 
                    } else { 
                        assetModelWrappers.add(new AssetModelWebService.AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), null, null, null));
                    }
                }else{//TODO:::need to check for if Offer enabled for NONE
                    assetModelWrappers.add(new AssetModelWebService.AssetModelItemWrapper(assetProgramDetailItem, insuranceById.get(assetProgramDetailItem.Insurance__c), null, null));
                }
                
            }
            
            
        }
        
        return assetModelWrappers;
    }
    
    
    public static map<string,decimal> findProductsInsurance(id partnerId, List<Object> productList){
        
        Map<string,double> productNameToTotalAmountMap = new Map<string,double>();
        
        Map<string,string> productNameToInsuranceCodeMap = new Map<string,string>();              
        
        for (Object productInfoItem : productList) {
            Map<String, Object> productInfo = (Map<String, Object>) productInfoItem;
            
            String productName = (String) productInfo.get('productname');
            
            if(! productNameToTotalAmountMap.containskey(productName)){
                productNameToTotalAmountMap.put(productName,Double.ValueOf((String) productInfo.get('totalprice')));
            }
        }        
        
        for(Asset_Program_Detail__c eachProduct : assetProgramDetailsList){
            
            productNameToInsuranceCodeMap.put(eachProduct.Product__r.name,eachProduct.Insurance__r.Code__c);
           
        }

            
            
            Map<string,decimal> prodductNameToPremuimValMap = findInsurancePremiumValue(productNameToTotalAmountMap,productNameToInsuranceCodeMap,insuranceLineItemList );
            
            
            return prodductNameToPremuimValMap;
        
    }  
    
                            
    
    /*
    * Name: findInsurancePremiumValue
    * Purpose: To find the premium cost for every insurance line item
    */
    public static  map<string,decimal> findInsurancePremiumValue(map<string,double> productNameToTotalAmountMap,map<string,string> productNameToInsuranceCodeMap,list<Insurance_Line_Item__c> insuranceLineItemList ){
        
        Map<string,decimal> prodductNameToPremuimValMap = new Map<string,decimal>();
        
        for(string prodName : productNameToTotalAmountMap.keyset()){
            for(Insurance_Line_Item__c eachInsuranceLintItem : insuranceLineItemList ){
                //if insurancecode matches         
                if(productNameToInsuranceCodeMap.get(prodName) == eachInsuranceLintItem.Insurance_code__c){
                    //compare the finance amount
                    if(eachInsuranceLintItem.Financial_Amount__c >= productNameToTotalAmountMap.get(prodName)){
                        prodductNameToPremuimValMap.put(prodName,eachInsuranceLintItem.Premium_cost__c);
                        break;
                    }  
                }
            }
        }
        
        return prodductNameToPremuimValMap; 
        //Can we check directly with Product+Total and insurance' premimum cost of assetprogram Detail's Product 
       
    }
    
    /*
    * Name: findProductsRV
    * Purpose: To find the RV matrix line item for a particualar product
    */
    //public static map<string,decimal> findProductsRV(Id applicableOfferId, id assetProgramId, id partnerId,List<Object> productList, Integer Term){
    public static map<string,decimal> findProductsRV(Map<Id,Insurance__C> insuranceById, List<Object> productList, Integer Term){
        
        List<String> productNameList = new List<String>();
        Map<string,decimal> prodductNameToRVValueMap = new map<string,decimal>();
        
        for (Object productInfoItem : productList) {
            Map<String, Object> productInfo = (Map<String, Object>) productInfoItem;
            
            if(! productNameList.contains((String) productInfo.get('productname'))){
                productNameList.add((String) productInfo.get('productname'));
            }
        }
        
        
        
        Map<String, String> RVProductMap = new Map<String, String> ();
        Set<Id> RVSet = new Set<Id> ();
        List<AssetModelWebService.AssetModelItemWrapper> assetProgramDetailWrappers = getAssetProgramDetailsWrappers(assetProgramDetailsList, RVMatrixMap.keyset(),insuranceById,rvType);//TODO need to test RVMatrixIds
        
        for (AssetModelWebService.AssetModelItemWrapper eachAssetModelItemWrapper : assetProgramDetailWrappers) {
            
            if(eachAssetModelItemWrapper.RVMatrixId != null){
               
                RVProductMap.put(eachAssetModelItemWrapper.assetProgramDetail.Product__r.Name, eachAssetModelItemWrapper.RVMatrixId + '-' + eachAssetModelItemWrapper.CategoryName);
                RVSet.add(eachAssetModelItemWrapper.RVMatrixId);
            }
        }
        
       
       
        List<RV_Matrix_Line_Item__c> rvMatrixLineItems= new List<RV_Matrix_Line_Item__c>();
        for(Id eachMatrixId : RVMatrixMap.keySet()){      
            if(RVSet.contains(eachMatrixId)){
                 rvMatrixLineItems.addAll(RVMatrixMap.get(eachMatrixId).RV_Matrix_Line_Items__r);
            }           
        }
        prodductNameToRVValueMap = findRVValue(productNameList,RVProductMap,rvMatrixLineItems,term);
        
        return prodductNameToRVValueMap;
        
    }
    
    /*
    * Name: findRVValue
    * Purpose: To find the RV Value for every RV Matrix line item
    */
    public static  map<string,decimal> findRVValue(List<String> productNameList , Map<String,String> RVProductMap, List<RV_Matrix_Line_Item__c> getRVMatrixLineItems, Integer Term){
        
        map<string,decimal> prodductNameToRVValueMap = new map<string,decimal>();
        
        for(string prodName : RVProductMap.keyset()){
            for(RV_Matrix_Line_Item__c eachRVMatrixLineItem : getRVMatrixLineItems){
                //if RV Matrix matches and it contains the product         
                if((RVProductMap.get(prodName).substringBefore('-') == eachRVMatrixLineItem.RV_Matrix__c) 
                   && (productNameList.contains(prodName)) 
                   && (RVProductMap.get(prodName).substringAfter('-') == eachRVMatrixLineItem.RV_Category__c)){
                    //compare the duration 
                    if(eachRVMatrixLineItem.Duration__r.Term_Value__c >= Term){
                        prodductNameToRVValueMap.put(prodName,eachRVMatrixLineItem.RV_Value__c);
                        break;
                    }  
                }
            }
        } 
        
        return prodductNameToRVValueMap;
    }
    
    
    /*
    * Name: buildJsonString
    * Purpose: build json structure for calling submit application from Public site
    */
    @AuraEnabled     
    public static String submitAppfromInvoiceSrc(String esignInfoId, Boolean isUBO, Boolean saveLogsAsync){
  
       
        List<QuoteSetupController.ServicertoquoteCls> servicesInfoList = new List<QuoteSetupController.ServicertoquoteCls>();
        List<QuoteSetupController.ProdtoquoteCls> prodInfoList = new List<QuoteSetupController.ProdtoquoteCls>();
        List<Map<String, Object>> ultimateBeneficiaries = new List<Map<String, Object>>();
        Map<String,String> invoiceMethodMap = new Map<String,String>{'PDF'=>'e-invoicing','Letter'=>'paper','EDI'=>'edi'};   
        
        
        //Query Quote and opportunity details on the basis of esigninfoId
        E_Sign_Information__c esignInfo = new WosSelector().getESignInfo(esignInfoId);
        
        //Query underlying lineitems of quote
        List<QuoteLineItem> quoteLineItemLst = new QuoteSetupController.WosSelector().getQuoteLineDetails(esignInfo.Quote__c);
       
        //Query Party contact details
        List<Contact> invoiceContact = new List<Contact>();
        if(isUBO){
            invoiceContact = new ESignInformationController.WoSSelector().getContacts(esignInfo.Opportunity__r.End_User__c);
        }
        
        
        for(QuoteLineItem eachLine : quoteLineItemLst){
            if(eachLine.Product2.Family == 'Maintenance'){
                
                QuoteSetupController.ServicertoquoteCls serviceInfo = new QuoteSetupController.ServicertoquoteCls(
                    String.valueof(eachLine.Quantity),
                    String.valueof(eachLine.UnitPrice),
                    String.valueof(eachLine.TotalPrice),
                    eachLine.Product2.name
                );
                servicesInfoList.add(serviceInfo);
            }else if (eachLine.Product2.Family != 'ITAD') {
                
                QuoteSetupController.ProdtoquoteCls prodtoQuoteObj = new QuoteSetupController.ProdtoquoteCls(
                    String.valueof(eachLine.Quantity),
                    String.valueof(eachLine.UnitPrice),
                    String.valueof(eachLine.TotalPrice),
                    eachLine.Product2.name,
                    eachLine.Description,
                    eachLine.Product2.Family
                );
                prodInfoList.add(prodtoQuoteObj);
            } 
        }   
        
        for(Contact invoiceCon : invoiceContact){            
            Map<String, Object> individualContact = new Map<String, Object>();
            individualContact.put('givenName',invoiceCon.FirstName!=null ? invoiceCon.FirstName : '');
            individualContact.put('familyName',invoiceCon.LastName);
            individualContact.put('middleName',invoiceCon.middleName!=null ? invoiceCon.middleName : '');
            individualContact.put('birthDate',invoiceCon.External_ID__c!=null ? invoiceCon.External_ID__c : '');
            individualContact.put('countryOfBirth',invoiceCon.Account.ShippingCountry !=null ?invoiceCon.Account.ShippingCountry :'');
            
            ultimateBeneficiaries.add(individualContact);
        }
        
        Map<String, Object> invoicingInfo = new Map<String, Object>();
        invoicingInfo.put('invoiceMethod',invoiceMethodMap.get(esignInfo.Opportunity__r.End_User__r.Invoice_Type__c));
        invoicingInfo.put('email', esignInfo.Opportunity__r.End_User__r.Email_Invoice__c);
        invoicingInfo.put('ediType', 'Peppol');//Hardcoded for Phase 2D
        invoicingInfo.put('ediReference', esignInfo.Opportunity__r.End_User__r.People_ID__c);
        invoicingInfo.put('department', esignInfo.Opportunity__r.End_User__r.C_O_Name__c != null
                                        ? esignInfo.Opportunity__r.End_User__r.C_O_Name__c :'');
        invoicingInfo.put('street',esignInfo.Opportunity__r.End_User__r.ShippingStreet);
        invoicingInfo.put('city', esignInfo.Opportunity__r.End_User__r.ShippingCity);
        invoicingInfo.put('postalCode', esignInfo.Opportunity__r.End_User__r.ShippingPostalCode);
        invoicingInfo.put('country', esignInfo.Opportunity__r.End_User__r.ShippingCountry);
                
        Map<String, Object> leaseContactMap = new Map<String, Object>{'name'=>esignInfo.Quote__r.Contact.Name,'email'=>esignInfo.Quote__r.Contact.email,
                                                                      'phoneNumber'=> esignInfo.Quote__r.Contact.Phone!=null ? esignInfo.Quote__r.Contact.Phone :''};
                                                                          
        Map<String, Object> deliveryAddressMap = new Map<String, Object>{'street'=>esignInfo.Quote__r.ShippingStreet != null ? esignInfo.Quote__r.ShippingStreet :'',
                                                                         'city'=>esignInfo.Quote__r.ShippingCity != null ? esignInfo.Quote__r.ShippingCity :'',
                                                                         'postalCode'=>esignInfo.Quote__r.ShippingPostalCode != null ? esignInfo.Quote__r.ShippingPostalCode : ''};
          
        //Create json structure for calling submit Application API                                                                 
        Map<String, Object> obj = new Map<String, Object>();
        obj.put('oppId', esignInfo.Opportunity__c);
        obj.put('oppName', esignInfo.Opportunity__r.name);
        obj.put('quoteId', esignInfo.Quote__c);
        obj.put('oppOwner', esignInfo.Opportunity__r.owner.Name);
        obj.put('programBU', esignInfo.Quote__r.Applicable_Offers__r.offer__r.Program__r.Business_Unit__r.name);
        obj.put('oppCreationDate', esignInfo.Opportunity__r.createddate);        
        obj.put('financialProductName', esignInfo.Quote__r.Applicable_Offers__r.name);
        obj.put('offerName', esignInfo.Quote__r.Applicable_Offers__r.offer__r.name);
        obj.put('dealerSalesPersonCode', esignInfo.Quote__r.CreatedBy.Final_Id__c);
        obj.put('oppCurrency', esignInfo.Opportunity__r.CurrencyIsoCode);
        obj.put('qouteTerm', esignInfo.Quote__r.Term__c);
        obj.put('paymentFrequency', esignInfo.Quote__r.Frequency__c);        
        obj.put('advanceArrear', esignInfo.Quote__r.Payment_Timing__c);
        obj.put('oppFinancedAmount', String.valueOf(esignInfo.Quote__r.Financed_Amount__c));
        obj.put('nominalInterestRate', esignInfo.Quote__r.Nominal_Interest_Rate__c);
        obj.put('productInfoList', prodInfoList);
        obj.put('serviceInfoList', servicesInfoList);
        obj.put('customerExtId', esignInfo.Opportunity__r.End_User__r.External_Identifier__c);        
        obj.put('customerId', esignInfo.Opportunity__r.End_User__c);
        obj.put('customerStreet', esignInfo.Opportunity__r.End_User__r.BillingStreet);
        obj.put('customerCity', esignInfo.Opportunity__r.End_User__r.BillingCity);
        obj.put('customerPostalCode', esignInfo.Opportunity__r.End_User__r.BillingPostalCode);
        obj.put('customerLegalName', esignInfo.Opportunity__r.End_User__r.Name);        
        obj.put('partnerName', esignInfo.Quote__r.Owner.FirstName+' '+esignInfo.Quote__r.Owner.LastName);
        obj.put('partnerEmail',esignInfo.Quote__r.Owner.email);
        obj.put('lesseeContact', leaseContactMap);
        obj.put('deliveryAddress', deliveryAddressMap);
        obj.put('insuranceMode', esignInfo.Quote__r.Insurance_Display_Options__c);
        
        obj.put('esignInfoId', esignInfoId);
      
        obj.put('invoicingInfo', invoicingInfo);
        obj.put('ultimateBeneficiaries', ultimateBeneficiaries);
        obj.put('reference', esignInfo.Quote__r.Reference__c != null ? esignInfo.Quote__r.Reference__c : '');
        
       
        // obj.put('specialTnCId',esignInfo.Quote__r.Description.split(';') );
        return RestCalloutHelper.makeSubmitAppRequest(JSON.Serialize(obj),saveLogsAsync);
        
    }
    
    
    private Static List<Map<String, Object>> requestBodyForPartyIdentifications(Quote quote,Map<String, Object> submitAppParams){
       
        
        Map<String, String> backOfficeParametersMap = getBackOfficeParameters(quote.Applicable_Offers__r.Offer__r.Program__c , quote.Account.id); 
        
        
        Map<String, Object> partyIdentification1 = new Map<String, Object>();
        partyIdentification1.put('identifierType', 'OrganizationNumber');
        partyIdentification1.put('identifierValue', quote.Account.Org_No__c != null ? quote.Account.Org_No__c : RESTCalloutHelper.setErrorField('Organization Number'));
        
        Map<String, Object> partyIdentification2 = new Map<String, Object>();
        partyIdentification2.put('identifierType', 'Supplier org');
        partyIdentification2.put('identifierValue', (String) backOfficeParametersMap.get('SupplierOrganization') != null ? (String) backOfficeParametersMap.get('SupplierOrganization') : RESTCalloutHelper.setErrorField('Supplier org'));  
        
        Map<String, Object> partyIdentification3 = new Map<String, Object>();
        partyIdentification3.put('identifierType', 'SFDC account id');
        partyIdentification3.put('identifierValue', quote.Account.Id != null ? quote.Account.Id : RESTCalloutHelper.setErrorField('SFDC account id'));
        
        Map<String, Object> partyIdentification4 = new Map<String, Object>();
        partyIdentification4.put('identifierType', 'Supplier Category');
        partyIdentification4.put('identifierValue', (String) backOfficeParametersMap.get('SupplierCategory') != null ? (String) backOfficeParametersMap.get('SupplierCategory') : RESTCalloutHelper.setErrorField('Supplier Category'));
        
        Map<String, Object> partyIdentification5 = new Map<String, Object>();
        partyIdentification5.put('identifierType', 'Partner cost center');
        partyIdentification5.put('identifierValue', (String) backOfficeParametersMap.get('PCC') != null ? (String) backOfficeParametersMap.get('PCC') : RESTCalloutHelper.setErrorField('Partner cost center'));
        
        Map<String, Object> partyIdentification6 = new Map<String, Object>();
        partyIdentification6.put('identifierType', 'Program Name');
        partyIdentification6.put('identifierValue', (String) quote.Applicable_Offers__r.Offer__r.Program__r.Name != null ? (String) quote.Applicable_Offers__r.Offer__r.Program__r.Name : RESTCalloutHelper.setErrorField('Program Name'));
        
        Map<String, Object> partyIdentification7 = new Map<String, Object>();
        partyIdentification7.put('identifierType', 'Applicable Offer Id');
        partyIdentification7.put('identifierValue', quote.Applicable_Offers__c != null ? quote.Applicable_Offers__c : RESTCalloutHelper.setErrorField('Applicable Offer Id'));
        
        Map<String, Object> partyIdentification8 = new Map<String, Object>();
        partyIdentification8.put('identifierType', 'Applicable Offer Name');
        partyIdentification8.put('identifierValue', quote.Applicable_Offers__r.Name != null ? quote.Applicable_Offers__r.Name : RESTCalloutHelper.setErrorField('Applicable Offer Name'));
        
        
        List<Map<String, Object>> partyIdentifications = new List<Map<String, Object>>{
            partyIdentification1, 
                partyIdentification2, 
                partyIdentification3,
                partyIdentification4,
                partyIdentification5,
                partyIdentification6,
                partyIdentification7,
                partyIdentification8
                };
                    
        return partyIdentifications;
       
    }    

    private Static List<Map<String, Object>> createPartiesNode(){
        
        SmartCommHelper.WoSSelector smartcommWOSelector = new SmartCommHelper.WoSSelector();
        Map<String, Object> data = new Map<String, Object>();
        data.put('name', quote.Account.Name != null ? quote.Account.Name : RESTCalloutHelper.setErrorField('Account Name'));
        data.put('dealerSalesPersonCode', quote.CreatedBy.Final_Id__c != null ? quote.CreatedBy.Final_Id__c : '');
        
         List<Map<String, Object>> partyIdentifications = requestBodyForPartyIdentifications(quote,submitAppParams);
        
        
        Map<String, Object> contact1 = new Map<String, Object>();
        contact1.put('name', quote.Owner.firstname +' '+ quote.Owner.lastname );
        contact1.put('email', quote.CreatedBy.Email != null ? quote.CreatedBy.Email : RESTCalloutHelper.setErrorField('partner Email'));
        
        List<Map<String, Object>> partyContact = new List<Map<String, Object>>{contact1};
        data.put('contact',partyContact );
        
        Boolean isDeemedAOD = false;
        //Map<String, Object> lesseeContact = new Map<String, Object>();
       
        
       
        
        //Second-Third Submit application   
        if(submitAppParams.get('lesseeContact') != null){
            
            if(!quote.Applicable_Special_Terms_and_Conditions__r.isEmpty()){
               
                for(Applicable_Special_Terms_and_Conditions__C eachObj :quote.Applicable_Special_Terms_and_Conditions__r){              
                    
                    if('Deemed_AOD'.equals(eachObj.Special_Terms_and_Conditions__r.Type__c)){
                        isDeemedAOD=true;                    
                    }
                }                
            }
            
            Map<String, Object> partyIdentification9 = new Map<String, Object>();
            partyIdentification9.put('identifierType', 'DeemedAod');           
            partyIdentification9.put('identifierValue', isDeemedAOD ? 'True' : 'False');
            partyIdentifications.add(partyIdentification9);
            
            
           }        
        
        data.put('identification', partyIdentifications);
        
        Map<String, Object> parties = new Map<String, Object>();
        parties.put('data', data);
        
        return new List<Map<String, Object>>{parties};
    }   
    
    
    private Static Map<String, Object> createLesseeNode(){
        
         String regionCode = quote.Applicable_Offers__r.Offer__r.Program__r.Region__r.ISO_Code__c;
         Map<String, Object> lessee = new Map<String, Object>();
        
        Map<String, Object> lesseeIdentification1 = new Map<String, Object>();
        lesseeIdentification1.put('identifierType', 'OrganizationNumber');
        lesseeIdentification1.put('identifierValue', (String) submitAppParams.get('customerExtId'));
        Map<String, Object> lesseeIdentification2 = new Map<String, Object>();
        lesseeIdentification2.put('identifierType', 'SFDC_Account id');
        lesseeIdentification2.put('identifierValue', (String) submitAppParams.get('customerId'));
        Map<String, Object> lesseeIdentification3 = new Map<String, Object>();
        lesseeIdentification3.put('identifierType', 'SFDC opportunity id');
        lesseeIdentification3.put('identifierValue', quote.OpportunityId != null ? quote.OpportunityId : RESTCalloutHelper.setErrorField('SFDC opportunity id'));
        
        List<Map<String, Object>> lesseeIdentifications = new List<Map<String, Object>>{
            lesseeIdentification1,
                lesseeIdentification2,
                lesseeIdentification3
                };
                    
        //lessee.put('soloTraderLegalName', Quote.Opportunity.Account.Legal_Entity_Description__c != null ? Quote.Opportunity.Account.Legal_Entity_Description__c : '');
        lessee.put('soloTraderLegalName', Quote.Opportunity.End_User__r.Legal_Entity_Name__c != null ? Quote.Opportunity.End_User__r.Legal_Entity_Name__c : '');
        lessee.put('identification', lesseeIdentifications);
        lessee.put('name', (String) submitAppParams.get('customerLegalName'));
               
        Map<String, Object> address = new Map<String, Object>();
        address.put('street', (String) submitAppParams.get('customerStreet'));
        address.put('city', ((String) submitAppParams.get('customerCity')).trim());
        address.put('postalCode', (String) submitAppParams.get('customerPostalCode'));
        address.put('country', regionCode);
       
        Map<String, Object> lesseeContact = new Map<String, Object>();
        if(submitAppParams.get('lesseeContact') != null){
             
              Map<String, Object> lesseeContactObj = (Map<String, Object>) submitAppParams.get('lesseeContact');
            
            lesseeContact.put('name', (String) lesseeContactObj.get('name'));
            lesseeContact.put('email', ((String) lesseeContactObj.get('email')).toLowercase());
            lesseeContact.put('type', 'Mobile');
            lesseeContact.put('number', (String) lesseeContactObj.get('phoneNumber') != null ? (String) lesseeContactObj.get('phoneNumber') : '');
        }
        
        lessee.put('address', address);
        lessee.put('contact', lesseeContact);
        
        //adding parameter for 3rd submitapplication structure
        if(submitAppParams.get('esignInfoId')!= null ){            
            List<Map<String, Object>> ultimateBeneficiaries = new List<Map<String, Object>>();
            for(Object obj: (List<Object>)submitAppParams.get('ultimateBeneficiaries')){
                ultimateBeneficiaries.add((Map<String, Object>)obj);
                
            }          
            
            lessee.put('invoicingInfo', (Map<String, Object>)submitAppParams.get('invoicingInfo'));
            lessee.put('ultimateBeneficiaries', ultimateBeneficiaries);
           // params.put('reference', (String)submitAppParams.get('reference'));//duplicate line??TODO:: need to verify
           
        }
       
       return lessee;
    }
    
  
    private Static Map<String, Object> createFinanceStructureNode(){
        Decimal rentalAmount=0.0;
        if(quote.Insurance_Display_Options__c == Constants.INCLUDED_IN_RENT){
            rentalAmount = quote.Rental_Amount__c  + (quote.Insurance_Amount__c != null ? quote.Insurance_Amount__c : 0);                
        }else{
            rentalAmount = quote.Rental_Amount__c;
        }
                                                             
        Decimal marginMatrixValue= getMarginMatrixValue(quote.Account.Margin_Matrix__c, Integer.valueOf(quote.Term__c), Decimal.valueOf((String)submitAppParams.get('oppFinancedAmount')));
        string cofandNominalRateString = getCofAndNominalRate(quote.Quote_Rate__c,((String) submitAppParams.get('paymentFrequency')).toLowerCase(),marginMatrixValue, Quote.Interest__c, termValue);
        
        //Create FinanceStructure Node
        Map<String, Object> financeStructure = new Map<String, Object>();
        
        // create Financial Product node under FinanceStructure
        Map<String, Object> financialProduct = new Map<String, Object>();
        financialProduct.put('financialProductType','OL');
        financialProduct.put('ContractScheme', (String) submitAppParams.get('offerName'));
        financialProduct.put('allowedMinimumDeposit', quote.Applicable_Offers__r.Offer__r.Program__r.Allowed_Minimum_Deposit__c != null ? String.valueof(quote.Applicable_Offers__r.Offer__r.Program__r.Allowed_Minimum_Deposit__c) : RESTCalloutHelper.setErrorField('allowed Minimum Deposit'));
        financialProduct.put('allowedMaximumDeposit', quote.Applicable_Offers__r.Offer__r.Program__r.Allowed_Maximum_Deposit__c != null ? String.valueof(quote.Applicable_Offers__r.Offer__r.Program__r.Allowed_Maximum_Deposit__c) : RESTCalloutHelper.setErrorField('allowed Maximum Deposit'));
        financialProduct.put('allowedTerms', quote.Applicable_Offers__r.Offer__r.Selectable_Agreement_Term__c != null ? quote.Applicable_Offers__r.Offer__r.Selectable_Agreement_Term__c : RESTCalloutHelper.setErrorField('allowed Terms'));  
        
        
        financeStructure.put('financialProduct', financialProduct);        
        financeStructure.put('startDate', quote.Opportunity.CreatedDate);
        financeStructure.put('endDate', quote.Opportunity.CloseDate);
        financeStructure.put('currency',(String) submitAppParams.get('oppCurrency'));
        financeStructure.put('numberOfMonths',Integer.valueOf((String)submitAppParams.get('qouteTerm')));
        financeStructure.put('paymentFrequency', ((String) submitAppParams.get('paymentFrequency')).toLowerCase());
        financeStructure.put('paymentTiming', (String) submitAppParams.get('advanceArrear'));     
        //DCV needs applied term along with interestBase
        //financeStructure.put('interestBase', Quote.Quote_Rate__r.Backoffice_Reference__c != null ? Quote.Quote_Rate__r.Backoffice_Reference__c : RESTCalloutHelper.setErrorField('interest Base'));
        financeStructure.put('interestBase', quote.Quote_Rate__r.Backoffice_Reference__c != null ? quote.Quote_Rate__r.Backoffice_Reference__c +'-'+ QuoteSetupController.getNextHighestTerm(quote.Applicable_Offers__r.Offer__r.Selectable_Agreement_Term__c,(String)submitAppParams.get('qouteTerm')) : RESTCalloutHelper.setErrorField('interest Base'));
        financeStructure.put('interestBaseRate', QuoteSetupController.getBaseRateFromRate(String.Valueof(quote.Applicable_Offers__r.Offer__c), (String)submitAppParams.get('qouteTerm'), ((String) submitAppParams.get('paymentFrequency')).toLowerCase(), quote.Interest__c));
       	financeStructure.put('periodicPaymentAmount', rentalAmount);
        
        if(submitAppParams.get('productInfoList')!=null){
            for (Object productInfoItem : (List<Object>) submitAppParams.get('productInfoList')) {
                 
                if(submitAppParams.ContainsKey('lesseeContact') ){
                    Map<String, Object> productInfo = (Map<String, Object>) productInfoItem;                
                    String productName = ((String) productInfo.get('productname'));
    
                    if(submitAppParams.get('insuranceMode') == Constants.INCLUDED_IN_RENT){
                        financeStructure.put('insuranceMode', 1);
                    }
                    else if(submitAppParams.get('insuranceMode') == Constants.ADDED_ON_INVOICE){
                        financeStructure.put('insuranceMode', 2);
                    }
                    else if(submitAppParams.get('insuranceMode') == Constants.DISPLAYED_SEPARATLY){
                        financeStructure.put('insuranceMode', 4);
                    }
                }
            }
        }

        //Create Finance node under FinanceStructure
         Map<String, Object> finance = new Map<String, Object>();
        finance.put('financeAmount', Decimal.valueOf((String) submitAppParams.get('oppFinancedAmount'))); 
       
         //Create NetDeposite node under Finance
        Map<String, Object> netDeposit = new Map<String, Object>();
        netDeposit.put('downPayment', quote.Value_downpayment__c != Null ? Decimal.valueOf(quote.Value_downpayment__c) :0.0 );
        finance.put('netDeposit', netDeposit);
        
        //Create Rates node under Finance
        Map<String, Object> rates = new Map<String, Object>();
        rates.put('nominalRate', Decimal.valueof(cofandNominalRateString.substringAfter('-')));
        rates.put('cof', Decimal.valueof(cofandNominalRateString.substringBefore('-')));           
        rates.put('margin', marginMatrixValue);
        finance.put('rates', rates);
        
         //Create Multiple CashFlows node under Finance
        List<Map<String, Object>> cashFlowsFinanceStructure = new List<Map<String, Object>>();
        
        Map<String, Object> CashFlowsFS1 = new Map<String, Object>();
        CashFlowsFS1.put('cashFlowType','fee');
        CashFlowsFS1.put('id', 'InvoiceFee');
        CashFlowsFS1.put('amount', Decimal.valueof((Integer)Quote.Account.Invoice_Fee_Amount__c) != null ? Decimal.valueof((Integer)Quote.Account.Invoice_Fee_Amount__c) : 0.0);
        //CashFlowsFS1.put('amount', Decimal.valueof((Integer)Quote.Invoice_Fee__c) != null ? Decimal.valueof((Integer)Quote.Invoice_Fee__c) : Decimal.valueof((Integer)Quote.Account.Invoice_Fee_Amount__c) != null ? Decimal.valueof((Integer)Quote.Account.Invoice_Fee_Amount__c) : 0.0);

        Map<String, Object> CashFlowsFS2 = new Map<String, Object>();  
        CashFlowsFS2.put('cashFlowType','fee');
        CashFlowsFS2.put('id', 'IssueFee');
        CashFlowsFS2.put('categoryCode', String.ValueOf(Quote.Account.Goes_to_DLL_partner_Startup__c) != null ? String.ValueOf(Quote.Account.Goes_to_DLL_partner_Startup__c) : '');
        CashFlowsFS2.put('amount', Decimal.valueof((Integer)Quote.Account.Start_Up_Fee_Amount__c) != null ? Decimal.valueof((Integer)Quote.Account.Start_Up_Fee_Amount__c) : 0.0);
        //CashFlowsFS2.put('amount', Decimal.valueof((Integer)Quote.Startup_Fee__c) != null ? Decimal.valueof((Integer)Quote.Startup_Fee__c) : Decimal.valueof((Integer)Quote.Account.Start_Up_Fee_Amount__c) != null ? Decimal.valueof((Integer)Quote.Account.Start_Up_Fee_Amount__c) : 0.0);
        
        Map<String, Object> CashFlowsFS3 = new Map<String, Object>();
        CashFlowsFS3.put('cashFlowType','fee');
        CashFlowsFS3.put('id', 'ExtensionFee');
        //CashFlowsFS3.put('amount', Decimal.valueof((Integer)Quote.Account.Extension_Factor_Percentage__c) != null ? Decimal.valueof((Integer)Quote.Account.Extension_Factor_Percentage__c) : 0.0);
        CashFlowsFS3.put('amount', getExtensionFeeAmount(rentalAmount));
        
        Map<String, Object> CashFlowsFS4 = new Map<String, Object>();
        CashFlowsFS4.put('cashFlowType','fee');
        CashFlowsFS4.put('id', 'IssueFeePercentDLL');
        CashFlowsFS4.put('amount', Decimal.valueof((Integer)Quote.Account.Start_Up_Fee_Split_Percentage__c) != null ? Decimal.valueof((Integer)Quote.Account.Start_Up_Fee_Split_Percentage__c) : 0.0);
        
        cashFlowsFinanceStructure.add(CashFlowsFS1);
        cashFlowsFinanceStructure.add(CashFlowsFS2);
        cashFlowsFinanceStructure.add(CashFlowsFS3);
        cashFlowsFinanceStructure.add(CashFlowsFS4);
        
    
        
        if(submitAppParams.get('serviceInfoList')!=null){
            for (Object serviceInfoList : (List<Object>) submitAppParams.get('serviceInfoList')) {
                
                Map<String, Object> serviceInfo = (Map<String, Object>) serviceInfoList;
                //String serviceName = ((String) serviceInfo.get('serviceName'));
                Map<String, Object> CashFlowsFS5 = new Map<String, Object>();
                CashFlowsFS5.put('cashFlowType','maintenance');
                CashFlowsFS5.put('id',(String) backOfficeParamProductsMap.get((String) serviceInfo.get('serviceName')));
                CashFlowsFS5.put('amount', Decimal.valueOf((String) serviceInfo.get('totalprice')));
                CashFlowsFS5.put('categoryName',(String) serviceInfo.get('serviceName'));
                cashFlowsFinanceStructure.add(CashFlowsFS5);
                
            } 
        }
        
        finance.put('cashFlows', cashFlowsFinanceStructure);
        financeStructure.put('finance', finance);
       
        
        return financeStructure;
    }
  
    private Static Map<String, Object> createAssestsAndSoftCostNode(){
       
        Map<String, Object> params = new Map<String, Object>();
                                                                        
        //Create SoftCosts Node    
        List<Map<String, Object>> softcosts = new List<Map<String, Object>>();
        //Create Assests Node    
        List<Map<String, Object>> assets = new List<Map<String, Object>>();
        
        if(submitAppParams.get('productInfoList')!=null){
            
            for (Object productInfoItem : (List<Object>) submitAppParams.get('productInfoList')) {
               
                Map<String, Object> productInfo = (Map<String, Object>) productInfoItem;                
                String productName = ((String) productInfo.get('productname'));
                String productType = ((String) productInfo.get('productType'));
                
                 //Create multiple Assest Node under Assests  
                Map<String, Object> asset = new Map<String, Object>();
                
                if(productType == Constants.ASSET_SOFT_PRODUCT_TYPE || productType == Constants.ASSET_HARD_PRODUCT_TYPE){
                    
                    //Create ModelIdentifier Node under each Assest node  
                    Map<String, Object> modelIdentifier = new Map<String, Object>();
                   
                    modelIdentifier.put('assetTypeName',productName);                    
                    modelIdentifier.put('description',(String) productInfo.get('specification'));
                    modelIdentifier.put('quantity',Integer.valueOf((String) productInfo.get('quantity')));
                    modelIdentifier.put('categoryId',(String) backOfficeParamProductsMap.get(productName) != null 
                                                     ? (String) backOfficeParamProductsMap.get(productName) 
                                                     : RESTCalloutHelper.setErrorField('BackOfficeParam'));
                    
                     //Create Location Node under each Assest node   
                    Map<String, Object> deliveryAddress = new Map<String, Object>();                    
                    
                    if(submitAppParams.get('deliveryAddress') != null){
                        
                        Map<String, Object> deliveryAddressObj = (Map<String, Object>) submitAppParams.get('deliveryAddress');
                        deliveryAddress.put('street',  deliveryAddressObj.get('street') != null ? (String) deliveryAddressObj.get('street') : '');
                        deliveryAddress.put('city',  deliveryAddressObj.get('city') != null ? (String) deliveryAddressObj.get('city') : '');
                        deliveryAddress.put('postalCode',  deliveryAddressObj.get('postalCode') != null ? (String) deliveryAddressObj.get('postalCode') : '');
                        
                    }
                    
                    asset.put('modelIdentifier', modelIdentifier);
                    asset.put('location', deliveryAddress);
                    asset.put('salePrice',Decimal.valueOf((String) productInfo.get('unitprice')));
                    
                    
                    
                    //Create multiple Identification Node under each Assest node  
                    Map<String, Object> identification = new Map<String, Object>();
                    
                    //Create Identifier Node under each Identification node  
                    Map<String, Object> identifier = new Map<String, Object>();
                    identifier.put('type','HW');
                    
                    identification.put('identifier',identifier);
                    asset.put('identification', identification);
                    
                    //Create FinanceInfo Node under each Assest node 
                    Map<String, Object> financeInfo = new Map<String, Object>();
                    financeInfo.put('financedAmount', Decimal.valueOf((String) productInfo.get('totalprice')));
                    
                    //Create Residual Node under FinanceInfo node
                    Map<String, Object> Residual = new Map<String, Object>();
                
                    //TODO:: fix as insurance rate fixed
                    Residual.put('rate', productNameToRvValueMap.containskey(productName) 
                                 ? productNameToRvValueMap.get(productName)
                                 : 0.0);
                    
                   // Residual.put('rate', (QLIMap.get(productName).Residual_Value_Rate__c/QLIMap.get(productName).UnitPrice * 100).setScale(2, RoundingMode.CEILING));
                   
                    
                    Residual.put('amount', QLIMap.get(productName).Residual_Value_Rate__c != null 
                                 ? QLIMap.get(productName).Residual_Value_Rate__c 
                                 : 0.0);  
                   
                   
                    if(prodNameToRvMatrixMap.containsKey(productName) 
                       && prodNameToRvMatrixMap.get(productName) != Null){
                           
                           Residual.put('guarantorName',(String) prodNameToRvMatrixMap.get(productName).Guarantor__r.Name);
                           Residual.put('guarantorOrganizationNumber', (String) prodNameToRvMatrixMap.get(productName).Guarantor__r.External_Identifier__c);
                           Residual.put('guarantorFinalNumber', (String) prodNameToRvMatrixMap.get(productName).Guarantor__r.Final_Id__c);     
                       }
                    else{
                        Residual.put('guarantorName', '');
                        Residual.put('guarantorOrganizationNumber', '');
                        Residual.put('guarantorFinalNumber', '');     
                    }
                    
                    financeInfo.put('Residual', Residual);
                    
                    //Create multiple CashFlows Node under Finance info Node for each Assest node  
                    List<Map<String, Object>> cashFlows = new List<Map<String, Object>>();
                    
                    Map<String, Object> CashFlows1 = new Map<String, Object>();
                    CashFlows1.put('cashFlowType', 'Insurance'); 
                    CashFlows1.put('id','InsuranceCode');
                    CashFlows1.put('categoryCode',QLIMap.get(productName).Insurance_Code__c != null ? QLIMap.get(productName).Insurance_Code__c : '');
                    
                    Map<String, Object> CashFlows2 = new Map<String, Object>();
                    CashFlows2.put('cashFlowType', 'Insurance');
                    CashFlows2.put('id','InsuranceRate'); 
                      
                    if(QLIMap.get(productName).Insurance_Code__c != null  )
                    {
                        //CashFlows2.put('categoryCode', productNameToPremiumInsuranceMap.get(productName)); 
                        CashFlows2.put('categoryCode', (QLIMap.get(productName).Insurance_Rate__c/QLIMap.get(productName).UnitPrice * 100).setScale(2, RoundingMode.CEILING));
                    }
                    else{
                        CashFlows2.put('categoryCode', 0.0);
                    }
                    
                    Map<String, Object> CashFlows3 = new Map<String, Object>();
                    CashFlows3.put('cashFlowType','fee');
                    CashFlows3.put('id','ItadType');
                    
                    if(QLIMap.get(productName).ITAD_Fee__c > 0  && Quote.ITAD_Category__c != Null ){
                        CashFlows3.put('categoryCode', Quote.ITAD_Category__c == Constants.DATA_WIPING 
                                       ? 'DW' 
                                       :  Quote.ITAD_Category__c == Constants.REVERSED_LOGISTICS 
                                       ? 'RL' 
                                       : 'OP');
                    }
                    else{
                        CashFlows3.put('categoryCode','');
                    }
                    
                    Map<String, Object> CashFlows4 = new Map<String, Object>();
                    CashFlows4.put('cashFlowType','fee');
                    CashFlows4.put('id','ItadFee');
                    CashFlows4.put('amount', QLIMap.get(productName).ITAD_Fee__c != null ? (Decimal) QLIMap.get(productName).ITAD_Fee__c : RESTCalloutHelper.setErrorField('Itad Fee'));
                    
                    Map<String, Object> CashFlows5 = new Map<String, Object>();
                    CashFlows5.put('cashFlowType','fee');
                    CashFlows5.put('id','RentalAmount');
                    CashFlows5.put('amount',  QLIMap.get(productName).Periodic_Amount__c != null ? (Decimal) QLIMap.get(productName).Periodic_Amount__c : RESTCalloutHelper.setErrorField('Rental Amount'));
                    
                    cashFlows.add(CashFlows1);
                    cashFlows.add(CashFlows2);
                    cashFlows.add(CashFlows3);
                    cashFlows.add(CashFlows4);
                    cashFlows.add(CashFlows5);
                    
                    financeInfo.put('cashFlows', cashFlows);                    
                    asset.put('financeInfo', financeInfo);
                    
                    assets.add(asset);
                }
                
                if(productType == Constants.SOFT_COST_PRODUCT_TYPE || productType == Constants.LICENCE_PRODUCT_TYPE || productType == Constants.INSTALLATION_PRODUCT_TYPE){
                    //Create multiple SoftCost Node under SoftCosts 
                    Map<String, Object> softcost = new Map<String, Object>();
                    
                    //Create Finance info Node for each SoftCost node
                    Map<String, Object> financeInfo = new Map<String, Object>();
                    
                    //Create multiple CashFlows Node under Finance info Node for each SoftCost node
                    List<Map<String, Object>> cashFlows = new List<Map<String, Object>>();
                    
                    if(productType == Constants.INSTALLATION_PRODUCT_TYPE){
                        Map<String, Object> CashFlows1 = new Map<String, Object>();
                        CashFlows1.put('cashFlowType', 'Insurance'); 
                        CashFlows1.put('id','InsuranceCode');                        
                        CashFlows1.put('categoryCode', QLIMap.get(productName).Insurance_Code__c != null
                                       ? QLIMap.get(productName).Insurance_Code__c
                                       : '');
                        
                        Map<String, Object> CashFlows2 = new Map<String, Object>();
                        CashFlows2.put('cashFlowType', 'Insurance');
                        CashFlows2.put('id','InsuranceRate'); 
                        
                        if(QLIMap.get(productName).Insurance_Code__c != null)
                        {
                            CashFlows2.put('categoryCode', (QLIMap.get(productName).Insurance_Rate__c/QLIMap.get(productName).UnitPrice * 100).setScale(2, RoundingMode.CEILING));
                        }
                        else{
                            CashFlows2.put('categoryCode', 0.0);
                        }
                        cashFlows.add(CashFlows1);
                        cashFlows.add(CashFlows2);
                    } 
                    
                    Map<String, Object> CashFlows3 = new Map<String, Object>();
                    CashFlows3.put('cashFlowType','fee');
                    CashFlows3.put('id','RentalAmount');
                    CashFlows3.put('amount',  QLIMap.get(productName).Periodic_Amount__c != null ? (Decimal) QLIMap.get(productName).Periodic_Amount__c : RESTCalloutHelper.setErrorField('Rental Amount'));
                    
                    cashFlows.add(CashFlows3);                    
                    financeInfo.put('cashFlows', cashFlows);
                    
                    
                    softcost.put('salePrice',Decimal.valueOf((String) productInfo.get('unitprice')));
                    softcost.put('financeInfo', financeInfo);
                    softcost.put('quantity',Integer.valueOf((String) productInfo.get('quantity')));
                    softcost.put('typename', productName);
                    softcost.put('categoryid',(String) backOfficeParamProductsMap.get(productName) != null 
                                               ? productType.deleteWhitespace() +'-'+ (String) backOfficeParamProductsMap.get(productName) 
                                               : productType.deleteWhitespace() + '- 0');
                    softcosts.add(softcost);
                } 
            }
        }
        
        params.put('assets', assets);
        params.put('softcosts', softcosts);
      return  params;
    }
    /**
    * Inner class-selector
    */
    public without sharing class WoSSelector {
        
        /**
        *Name: getQuotesWithAssessmentStatus
        *Purpose: Returns query for assessment and opportunityId from quote
        */
        private List<Quote> getQuotesWithAssessmentStatus(String opportunityId) {             
            return [SELECT Id FROM Quote WHERE Status = :Constants.QUOTE_CALCULATION_EXPIRED_STATUS AND opportunityId = :opportunityId];               
        }
        
        
        
        private List<Rate_Line_Item__c> getRateLineItemsByRateId(Id rateId) {
            return [
                SELECT Id, Term__r.Alias__c, Term__r.Term_Value__c,Rate_Value__c,Rate__r.Cost_Of_Funds__c 
                FROM Rate_Line_Item__c 
                WHERE Rate__c =: rateId
            ];
        }
        
        
        
        /**
        *Name: getQuoteDetails
        *Purpose: queries all body parameters from quote.  
        */
        private Quote getQuoteDetails(String quoteId) {    
            return 
                [
                    SELECT 
                    Id,
                    (SELECT UnitPrice, Insurance_Code__c, Periodic_Amount__c, Insurance_Rate__c, ITAD_Fee__c, Residual_Value_Rate__c, Type_Id__c, 
                     Product2.Name from QuoteLineItems where QuoteId =:quoteId ),
                    (select id,Special_Terms_and_Conditions__c,Name,Special_Terms_and_Conditions__r.type__c,
                     Special_Terms_and_Conditions__r.Body__c   from Applicable_Special_Terms_and_Conditions__r where Quote__c =:quoteId),
                    Name, 
                    //Startup_Fee__c,
                   // Invoice_Fee__c,
                    Owner.firstname,Owner.lastname, 
                    CreatedBy.Final_Id__c,
                    CreatedBy.Email,
                    Valid_From__c,  
                    Account.Name,
                    Account.id,
                    Account.Doing_Business_As__c, 
                    Account.Org_No__c,
                    Account.Invoice_Fee_Amount__c,
                    //Account.Extension_Fee__c,
                    Account.Extension_Factor_Percentage__c,
                    Account.Start_Up_Fee_Amount__c,
                    Account.Start_Up_Fee_Split_Percentage__c,
                    Account.Goes_to_DLL_partner_Startup__c,
                    Account.External_Identifier__c, 
                    Account.Margin_Matrix__c,
                    Account.Low_Touch_Flag__c,
                    Account.Final_Id__c,
                    Applicable_Offers__c,
                    Applicable_Offers__r.Name, 
                    Applicable_Offers__r.Offer__r.Name,                    
                    OpportunityId,  
                    Opportunity.Name,
                    Value_downpayment__c,
                    Opportunity.Owner.Name, 
                    Opportunity.CreatedDate, 
                    Opportunity.CloseDate,
                    Opportunity.CurrencyIsoCode,               
                    Quote_Rate__r.Cost_Of_Funds__c,
                    Term__c, 
                    Insurance_Display_Options__c,
                    Insurance_Amount__c,
                    Applicable_Offers__r.Offer__r.Program__r.Region__r.ISO_Code__c,
                    Applicable_Offers__r.Offer__r.Program__r.Business_Unit__r.Business_Unit_Code__c,
                    Applicable_Offers__r.Offer__r.Program__r.Business_Unit__r.Name,
                    Applicable_Offers__r.Offer__c,
                    Applicable_Offers__r.Offer__r.Program__r.Name,
                    //Applicable_Offers__r.Offer__r.IS_RV_Applicable__c,
                    Applicable_Offers__r.Offer__r.RV_Type__c,
                    Applicable_Offers__r.Offer__r.Program__r.Asset_Program__c,
                    Applicable_Offers__r.Offer__r.Selectable_Agreement_Term__c,
                    Applicable_Offers__r.Offer__r.Program__r.Allowed_Maximum_Deposit__c,
                    Applicable_Offers__r.Offer__r.Program__r.Allowed_Minimum_Deposit__c,
                    Opportunity.End_User__r.name,
                    Opportunity.End_User__r.BillingAddress,
                    Opportunity.End_User__r.Org_No__c,
                    Opportunity.End_User__r.Phone,
                    Opportunity.Account.Name,
                    Opportunity.Account.Doing_Business_As__c,
                    Opportunity.Account.BillingAddress  ,
                    Opportunity.Account.Org_No__c,
                    Opportunity.Account.Website,
                    Opportunity.Account.Phone,
                    Opportunity.Account.Start_Up_Fee_Amount__c,
                    //Opportunity.Account.Extension_Fee__c,
                    //Opportunity.Account.Legal_Entity_Description__c,
                    Opportunity.End_User__r.Legal_Entity_Name__c,
                    Contact.Email,
                    Contact.Name,
                    Contact.Phone,
                    Financed_Amount__c,
                    Rental_Amount__c,
                    Frequency__c,
                    ITAD_Category__c,
                    Payment_Timing__c,
                    Quote_Rate__r.Name,
                    Quote_Rate__r.Date__c,
                    Quote_Rate__r.Rate_Type__c,
                    Quote_Rate__r.Backoffice_Reference__c,
                    Applicable_Offers__r.Offer__r.Contract_Document__c,
                    Applicable_Offers__r.Offer__r.Extension_Code__c,
                    Applicable_Offers__r.Offer__r.General_Terms_and_Conditions__r.SmartComTemplateReference__c,
                    Applicable_Offers__r.Offer__r.General_Terms_and_Conditions__r.Name,
                   	Interest__c,
                    Reference__c
                    FROM Quote
                    WHERE Id = :quoteId
                ];     
        }

        private List<BackOffice_Param__c> getBOParamsByAuthorizedPrograms(Id programId, Id accountId) {
            return [SELECT Type__c, Value__c FROM BackOffice_Param__c 
                    WHERE Authorized_Program__r.Program__c = :programId and Authorized_Program__r.Dealer__c=:accountId ];
        }
        
        private Margin_Matrix_Item__c getMarginLineItemsByMargimMatrixId(Id marginMatrixId,Integer selectedTerm, Decimal selectedAmount) {
            return [
                SELECT Financial_Amount__c, Term__r.Term_Value__c, Value__c
                FROM Margin_Matrix_Item__c
                WHERE Margin_Matrix__c = :marginMatrixId and Term__r.Term_Value__c >= :selectedTerm and Financial_Amount__c >= :selectedAmount
                ORDER BY Term__r.Term_Value__c, Financial_Amount__c asc NULLS LAST limit 1
            ];
        }
        
        private String getAccountTeamMemberDetails(Id accountId) {
            
            list<AccountTeamMember> accTeamMemberLst = [SELECT user.Final_Id__c FROM AccountTeamMember WHERE AccountId =:accountId AND TeamMemberRole = :Constants.ACCOUNT_MANAGER_ROLE limit 1];
            
            if(accTeamMemberLst.size() == 0){
                return null;
            }
            return accTeamMemberLst[0].user.Final_Id__c;
            
        }
        
       
        private List<Asset_Program_Detail__c> getAssetProgramDetails(id assetProgramId){
            
            return [SELECT Id,Product__c,Product__r.Name, Product__r.Family, Product__r.Brand__c,
                    Insurance__c, Insurance__r.name,  Insurance__r.Code__c,
                    Is_RV_Applicable__c,  BackOffice_Param__r.Value__c, 
                    RV_Category_1__c, RV_Category_2__c, RV_Category_3__c, RV_Category_4__c, RV_Category_5__c, 
                    RV_Priority_1__c, RV_Priority_2__c, RV_Priority_3__c, RV_Priority_4__c, RV_Priority_5__c,
                    ITAD_Product__r.Name,
                    Default_Purchase_Option__c,Max_Purchase_Option__c,Min_Purchase_Option__c
                    FROM Asset_Program_Detail__c 
                    WHERE Asset_Program__c=: assetProgramId                   
                   ];
        }
        
        
        
        private List<Insurance__c> getInsuranceById(Set<Id> insuranceIds, Id partnerId) {
            return [
                SELECT  Id, (SELECT  name, id, Financial_Amount__c,Premium_cost__c,
                             Insurance_code__c ,Insurance__c 
                             FROM Insurance_Line_Item__r WHERE Partner__c = :partnerId 
                             ORDER BY Insurance_code__c,Financial_Amount__c ASC nulls last)
                FROM    Insurance__c
                WHERE   Id IN :insuranceIds
            ];
        }
        
       
        
        /**
        * SOQL on the Esign information object to get the quote and opportunity details for building submit application requ structure through public site
        */
        private E_Sign_Information__c getESignInfo(Id eSignInfoId) {
            return [
                SELECT  Id, Name, Status__c,
                Opportunity__c, //oppId
                Opportunity__r.name, //oppName
                Opportunity__r.owner.Name, //oppOwner
                Opportunity__r.createddate,//oppCreationDate
                Opportunity__r.CurrencyIsoCode,//oppCurrency
                Opportunity__r.End_User__c,//ultimateBeneficiaries
                Opportunity__r.End_User__r.External_Identifier__c, //customerExtId ,customerId
                Opportunity__r.End_User__r.Name,//customerLegalName
                Opportunity__r.End_User__r.BillingStreet, //customerStreet
                Opportunity__r.End_User__r.BillingCity ,//customerCity
                Opportunity__r.End_User__r.BillingPostalCode, //customerPostalCode                         
                Opportunity__r.End_User__r.Invoice_Type__c,//invoicingInfo
                Opportunity__r.End_User__r.People_ID__c,//Peppol ID
                Opportunity__r.End_User__r.Reference__c,//invoiceReference
                Opportunity__r.End_User__r.Email_Invoice__c,//invoicingInfo
                Opportunity__r.End_User__r.C_O_Name__c,//invoicingInfo                
                Opportunity__r.End_User__r.ShippingStreet,//invoicingInfo
                Opportunity__r.End_User__r.ShippingCity,//invoicingInfo
                Opportunity__r.End_User__r.ShippingCountry,//invoicingInfo
                Opportunity__r.End_User__r.ShippingPostalCode, //invoicingInfo
                Quote__c, //quoteId
                Quote__r.Description, //SpeTnCIds
                Quote__r.Owner.FirstName, //partnerName
                Quote__r.Owner.LastName, //partnerName
                Quote__r.Owner.email, //partneremail
                Quote__r.CreatedBy.Final_Id__c,//partnerFinalId
                Quote__r.Applicable_Offers__r.name, // financialProductName
                Quote__r.Applicable_Offers__r.offer__r.name,//offerName
                Quote__r.Term__c, //qouteTerm
                Quote__r.Frequency__c, //paymentFrequency
                Quote__r.Payment_Timing__c, //advanceArrear
                Quote__r.Financed_Amount__c, //oppFinancedAmount
                Quote__r.Nominal_Interest_Rate__c, //nominalInterestRate
                Quote__r.Applicable_Offers__r.offer__r.Program__r.Business_Unit__r.name,   //programBU
                Quote__r.Contact.Name, //lesseeContact
                Quote__r.Contact.email, //lesseeContact
                Quote__r.Contact.Phone, //lesseeContact
                Quote__r.ShippingStreet, //deliveryAddress
                Quote__r.ShippingCity, //deliveryAddress
                Quote__r.ShippingPostalCode, //deliveryAddress
                Quote__r.Reference__c, //invoicereference
                Quote__r.Insurance_Display_Options__c //insuranceMode
                
                FROM    E_Sign_Information__c 
                WHERE   Id = :eSignInfoId
            ];
        }
        
        
        
        public List<Applicable_RV__c> getApplicableRVs(Id offerId) {
            return [
                SELECT  RV_Matrix__c
                FROM    Applicable_RV__c
                WHERE   Offer__c =: offerId
            ];
        }
        
    
        /*
         * Query RV Matrix along with its line items by RvMatrix Ids and return map of RVMatrix 
        */
        public Map<Id,RV_Matrix__c> getRVMatrixByIds(Set<Id> RVMatrix) {
            
            Map<Id,RV_Matrix__c> matrixIdToRvMatrixMap = new Map<Id,RV_Matrix__c>
                ([SELECT  Id, Guarantor__r.Name, Guarantor__r.External_Identifier__c,
                  Guarantor__r.Final_Id__c,
                  (SELECT Id, name ,Duration__c,Duration__r.Term_Value__c,
                   RV_Category__c,RV_Value__c,RV_Matrix__c  
                   FROM RV_Matrix_Line_Items__r 
                   ORDER BY Duration__r.Term_Value__c ASC nulls last) 
                  FROM RV_Matrix__c WHERE Id IN : RVMatrix]);
            
            return matrixIdToRvMatrixMap;            
        }
    }
    
}