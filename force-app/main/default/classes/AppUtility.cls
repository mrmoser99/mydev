/**
 * @description       : 
 * @author            : Mark Moser
 * @group             : 
 * @last modified on  : 02-21-2023
 * @last modified by  : Mark Moser
 * Modifications Log
 * Ver   Date         Author       Modification
 * 1.0   01-23-2023   Mark Moser   Initial Version Modified
 * Change Log:
 * 
 * 02/21/2023 - MRM Fixed Accessory Issue
**/
public without sharing class AppUtility{

    @AuraEnabled  
    public static Map<String,String> getQuoteOpportunityAndCount(String quoteNumber){
        
        Map<String,String> resultMap = new Map<String,String>();

        try{

            List<Quote> qList = [select opportunityId from Quote where quote_number__c = :quoteNumber];
            if (!qList.isEmpty()){
                resultMap.put('opportunityId',qList[0].opportunityId);
                resultMap.put('count', String.valueOf(qList.size()));
            
                return resultMap;
            }

        }
            
        catch (Exception e){
        }
        
        return null;
    }

    /*****************************************************************************************************************
    *  if there is already an appeal; return that appeals option number
    *
    *  if it is a new appeal, then copy the orginal quote and quote and quote lines into
    *  a new set quote and quote lines; mark the quote as an appeal
    *
    *  return appeal option number or erorr numbers
    *******************************************************************************************************************/

    @AuraEnabled  
    public static String generateAppealQuoteOption(ID sourceOppId, ID destinationOppId, String quoteNumber, Integer qCount){
        try{

            Opportunity o = [select Id
                        ,quote_count__c
                        from Opportunity 
                        where id = :destinationOppId
                        
                        ];

            

            //check for existing appeal
            List<Quote> qList = [select id
                                ,option_number__c
                                 from Quote
                                 where opportunityId = :o.Id
                                 and is_appeal__c = true
                                 ];
            
            //if there is already an appeal in the destination, then just return that option number
            if (!qLIst.isEmpty()){
                return String.valueOf(qList[0].option_number__c);
            }
 
            system.debug('quote count is ' + o.quote_count__c);
            //if quote count is zero, then this is a credit check.  credit checks don't have quotes until the appeal process

            if (o.quote_count__c != 0){
                return creditWithQuoteOption(destinationOppId);
            }
            else{
                return creditWithOutQuoteOption(sourceOppId, destinationOppId,quoteNumber,qCount);
            }
    

        }
        catch (Exception e){

            
        }
        
        return null;
    }

    /**********************************************************************************************************************************
     * This class sets up the quote data for an appeal for an application that has a quote
     * 
     * 
     **********************************************************************************************************************************/ 
    static String creditWithQuoteOption(ID opportunityId){

        List<Quote> qList = new List<Quote>();

        system.debug('opp is: ' + opportunityId);
        
            
        Quote q = [SELECT
                                AccountId,
                                Accumulated_Service__c,
                                AdditionalAddress,
                                AdditionalCity,
                                AdditionalCountry,
                                AdditionalGeocodeAccuracy,
                                AdditionalLatitude,
                                AdditionalLongitude,
                                AdditionalName,
                                AdditionalPostalCode,
                                AdditionalState,
                                AdditionalStreet,
                                Advance_Payments__c,
                                Amount__c,
                                Applicable_Offers__c,
                                Applied_Purchase_Option__c,
                                Asset_Type__c,
                                Auto_Decision__c,
                                Base_Unit_Sales_Price__c,
                                BillingAddress,
                                BillingCity,
                                BillingCountry,
                                BillingGeocodeAccuracy,
                                BillingLatitude,
                                BillingLongitude,
                                BillingName,
                                BillingPostalCode,
                                BillingState,
                                BillingStreet,
                                Calculate_By__c,
                                CanCreateQuoteLineItems,
                                Case_Number__c,
                                Code_downpayment__c,
                                Code_Loss_pool__c,
                                Code_Other__c,
                                Code_term__c,
                                Code_URA__c,
                                Comments__c,
                                Conditions__c,
                                ContactId,
                                ContractId,
                                Created_Date__c,
                                CreatedById,
                                CreatedDate,
                                Credit_Report_URL__c,
                                Credit_Underwriter_Email__c,
                                Credit_Underwriter_Name__c,
                                Credit_Underwriter_Phone__c,
                                CurrencyIsoCode,
                                Current_Credit_App_Selection__c,
                                Customer_Account__c,
                                Decision_Maker__c,
                                Description,
                                Description_downpayment__c,
                                Description_Loss_Pool__c,
                                Description_Other__c,
                                Description_term__c,
                                Description_URA__c,
                                Disabled_Calculation_Params__c,
                                Discount,
                                Downpayment__c,
                                Email,
                                End_User__c,
                                Expiration_Date__c,
                                ExpirationDate,
                                Fax,
                                Finance_Term_Month__c,
                                Financed_Amount__c,
                                Frequency__c,
                                Future_Value__c,
                                GrandTotal,
                                Id,
                                Include_In_Proposal__c,
                                Insurance_Amount__c,
                                Insurance_Display_Options__c,
                                Interest__c,
                                Is_Primary__c,
                                IsDeleted,
                                IsSyncing,
                                ITAD_Category__c,
                                ITAD_Fee__c,
                                LastModifiedById,
                                LastModifiedDate,
                                LastReferencedDate,
                                LastViewedDate,
                                Lease_Type__c,
                                LineItemCount,
                                Location_ID__c,
                                Manual_Decision__c,
                                Name,
                                Nominal_Interest_Rate__c,
                                OpportunityId,
                                Option_Number__c,
                                OwnerId,
                                Owner.Type,
                                Owner.Name,
                                Owner.FirstName,
                                Owner.LastName,
                                Partner_Sales_Rep__c,
                                Payment_Frequency__c,
                                Payment_Timing__c,
                                Phone,
                                Pricebook2Id,
                                Program__c,
                                Program_ID__c,
                                Quote_Number__c,
                                Quote_Rate__c,
                                QuoteNumber,
                                QuoteToAddress,
                                QuoteToCity,
                                QuoteToCountry,
                                QuoteToGeocodeAccuracy,
                                QuoteToLatitude,
                                QuoteToLongitude,
                                QuoteToName,
                                QuoteToPostalCode,
                                QuoteToState,
                                QuoteToStreet,
                                Rate_Type__c,
                                Rate_Type_Id__c,
                                Recalculation__c,
                                RecordTypeId,
                                Reference__c,
                                Rent_Per_Month__c,
                                Rental_Amount__c,
                                Residual__c,
                                Revenue__c,
                                ShippingAddress,
                                ShippingCity,
                                ShippingCountry,
                                ShippingGeocodeAccuracy,
                                ShippingHandling,
                                ShippingLatitude,
                                ShippingLongitude,
                                ShippingName,
                                ShippingPostalCode,
                                ShippingState,
                                ShippingStreet,
                                SmartComm_Docs_Count__c,
                                Status,
                                Status_Priority__c,
                                Subsidy_Rate_Type_Id__c,
                                Subtotal,
                                SystemModstamp,
                                Tax,
                                Term__c,
                                Total_Payment__c,
                                Total_Price__c,
                                TotalPrice,
                                Type_downpayment__c,
                                Type_Loss_Pool__c,
                                Type_Other__c,
                                Type_term__c,
                                Type_URA__c,
                                Use_Subsidy__c,
                                Valid_From__c,
                                Valid_To__c,
                                Value_downpayment__c,
                                Value_Loss_Pool__c,
                                Value_Other__c,
                                Value_term__c,
                                Value_URA__c        
                            FROM
                            Quote
                            where is_primary__c = true   
                            and opportunityId = :opportunityId
                            ];

         

        List<Quote_Line__c> qLineList = [SELECT
                                            Annual_Hours__c,
                                            Asset_Condition__c,
                                            Asset_Type__c,
                                            Asset_Type_ITA_Class__c,
                                            Asset_Type_ITA_Class_Id__c,
                                            Base_Unit_Sales_Price__c,
                                            Battery_Included__c,
                                            Billed_Residual_Amount__c,
                                            Booked_Residual_Amount__c,
                                            CreatedById,
                                            CreatedDate,
                                            CurrencyIsoCode,
                                            Equipment_Type__c,
                                            Id,
                                            IsDeleted,
                                            LastActivityDate,
                                            LastModifiedById,
                                            LastModifiedDate,
                                            Make__c,                                        
                                            Make_Id__c,
                                            Mast_Type__c,
                                            Model__c,
                                            Model_Id__c,
                                            MSRP__c,
                                            Name,
                                            Number_of_Units__c,
                                            Operating_Environment__c,
                                            Payment_Amount__c,
                                            Quote__c,
                                            Related_Asset__c,
                                            Subsidy__c,
                                            Subsidy_ID__c,
                                            SystemModstamp,
                                            Total_Sales_Price_Base__c
                                        FROM
                                        Quote_Line__c
                                        where quote__c = :q.id
                                        ] ;

        q.id = null;
        Quote qClone = q;
        qClone.option_number__c = q.option_number__c + 1;
        qClone.is_primary__c = false;
         
        qClone.is_appeal__c = true;
        qClone.Include_In_Proposal__c = true;
        qClone.Current_Credit_App_Selection__c = true;

        insert qClone;

        for (Quote_Line__c ql:qLineList){
            ql.id = null;
            ql.quote__c = qClone.id;
        }
        List<Quote_Line__c> qLineListClone = qLineList;
    
            
        if (!qLineListClone.isEmpty()){
            insert qLineListClone;
        }

        
        return String.valueOf(qClone.option_number__c);

    }


    /**********************************************************************************************************************************
     * This class sets up the quote data for an appeal for an application that does not have a quote
     * 
     * if the quoteId is null, then it means create a new quote
     * if the quoteId is not null, then copy that quote data from the selected option to this opportunity
     **********************************************************************************************************************************/ 
    static String creditWithOutQuoteOption(ID sourceOppId, ID destinationOppId, String quoteNumber, Integer qCount){

        if (quoteNumber == null)
            return 'New Option';
        
        //get quote and quote lines for the quote number
        Quote q;

        system.debug('source is: ' + sourceOppId + ' destination is: ' + destinationOppId);

        if (qCount == 1){
            q = [SELECT
                                AccountId,
                                Accumulated_Service__c,
                                AdditionalAddress,
                                AdditionalCity,
                                AdditionalCountry,
                                AdditionalGeocodeAccuracy,
                                AdditionalLatitude,
                                AdditionalLongitude,
                                AdditionalName,
                                AdditionalPostalCode,
                                AdditionalState,
                                AdditionalStreet,
                                Advance_Payments__c,
                                Amount__c,
                                Applicable_Offers__c,
                                Applied_Purchase_Option__c,
                                Asset_Type__c,
                                Auto_Decision__c,
                                Base_Unit_Sales_Price__c,
                                BillingAddress,
                                BillingCity,
                                BillingCountry,
                                BillingGeocodeAccuracy,
                                BillingLatitude,
                                BillingLongitude,
                                BillingName,
                                BillingPostalCode,
                                BillingState,
                                BillingStreet,
                                Calculate_By__c,
                                CanCreateQuoteLineItems,
                                Case_Number__c,
                                Code_downpayment__c,
                                Code_Loss_pool__c,
                                Code_Other__c,
                                Code_term__c,
                                Code_URA__c,
                                Comments__c,
                                Conditions__c,
                                ContactId,
                                ContractId,
                                Created_Date__c,
                                CreatedById,
                                CreatedDate,
                                Credit_Report_URL__c,
                                Credit_Underwriter_Email__c,
                                Credit_Underwriter_Name__c,
                                Credit_Underwriter_Phone__c,
                                CurrencyIsoCode,
                                Current_Credit_App_Selection__c,
                                Customer_Account__c,
                                Decision_Maker__c,
                                Description,
                                Description_downpayment__c,
                                Description_Loss_Pool__c,
                                Description_Other__c,
                                Description_term__c,
                                Description_URA__c,
                                Disabled_Calculation_Params__c,
                                Discount,
                                Downpayment__c,
                                Email,
                                End_User__c,
                                Expiration_Date__c,
                                ExpirationDate,
                                Fax,
                                Finance_Term_Month__c,
                                Financed_Amount__c,
                                Frequency__c,
                                Future_Value__c,
                                GrandTotal,
                                Id,
                                Include_In_Proposal__c,
                                Insurance_Amount__c,
                                Insurance_Display_Options__c,
                                Interest__c,
                                Is_Primary__c,
                                IsDeleted,
                                IsSyncing,
                                ITAD_Category__c,
                                ITAD_Fee__c,
                                LastModifiedById,
                                LastModifiedDate,
                                LastReferencedDate,
                                LastViewedDate,
                                Lease_Type__c,
                                LineItemCount,
                                Location_ID__c,
                                Manual_Decision__c,
                                Name,
                                Nominal_Interest_Rate__c,
                                OpportunityId,
                                Option_Number__c,
                                OwnerId,
                                Owner.Type,
                                Owner.Name,
                                Owner.FirstName,
                                Owner.LastName,
                                Partner_Sales_Rep__c,
                                Payment_Frequency__c,
                                Payment_Timing__c,
                                Phone,
                                Pricebook2Id,
                                Program__c,
                                Program_ID__c,
                                Quote_Number__c,
                                Quote_Rate__c,
                                QuoteNumber,
                                QuoteToAddress,
                                QuoteToCity,
                                QuoteToCountry,
                                QuoteToGeocodeAccuracy,
                                QuoteToLatitude,
                                QuoteToLongitude,
                                QuoteToName,
                                QuoteToPostalCode,
                                QuoteToState,
                                QuoteToStreet,
                                Rate_Type__c,
                                Rate_Type_Id__c,
                                Recalculation__c,
                                RecordTypeId,
                                Reference__c,
                                Rent_Per_Month__c,
                                Rental_Amount__c,
                                Residual__c,
                                Revenue__c,
                                ShippingAddress,
                                ShippingCity,
                                ShippingCountry,
                                ShippingGeocodeAccuracy,
                                ShippingHandling,
                                ShippingLatitude,
                                ShippingLongitude,
                                ShippingName,
                                ShippingPostalCode,
                                ShippingState,
                                ShippingStreet,
                                SmartComm_Docs_Count__c,
                                Status,
                                Status_Priority__c,
                                Subsidy_Rate_Type_Id__c,
                                Subtotal,
                                SystemModstamp,
                                Tax,
                                Term__c,
                                Total_Payment__c,
                                Total_Price__c,
                                TotalPrice,
                                Type_downpayment__c,
                                Type_Loss_Pool__c,
                                Type_Other__c,
                                Type_term__c,
                                Type_URA__c,
                                Use_Subsidy__c,
                                Valid_From__c,
                                Valid_To__c,
                                Value_downpayment__c,
                                Value_Loss_Pool__c,
                                Value_Other__c,
                                Value_term__c,
                                Value_URA__c        
                            FROM
                            Quote
                            where opportunityId = :sourceOppId 
                            ];
        }
        else{
                 q = [SELECT
                                AccountId,
                                Accumulated_Service__c,
                                AdditionalAddress,
                                AdditionalCity,
                                AdditionalCountry,
                                AdditionalGeocodeAccuracy,
                                AdditionalLatitude,
                                AdditionalLongitude,
                                AdditionalName,
                                AdditionalPostalCode,
                                AdditionalState,
                                AdditionalStreet,
                                Advance_Payments__c,
                                Amount__c,
                                Applicable_Offers__c,
                                Applied_Purchase_Option__c,
                                Asset_Type__c,
                                Auto_Decision__c,
                                Base_Unit_Sales_Price__c,
                                BillingAddress,
                                BillingCity,
                                BillingCountry,
                                BillingGeocodeAccuracy,
                                BillingLatitude,
                                BillingLongitude,
                                BillingName,
                                BillingPostalCode,
                                BillingState,
                                BillingStreet,
                                Calculate_By__c,
                                CanCreateQuoteLineItems,
                                Case_Number__c,
                                Code_downpayment__c,
                                Code_Loss_pool__c,
                                Code_Other__c,
                                Code_term__c,
                                Code_URA__c,
                                Comments__c,
                                Conditions__c,
                                ContactId,
                                ContractId,
                                Created_Date__c,
                                CreatedById,
                                CreatedDate,
                                Credit_Report_URL__c,
                                Credit_Underwriter_Email__c,
                                Credit_Underwriter_Name__c,
                                Credit_Underwriter_Phone__c,
                                CurrencyIsoCode,
                                Current_Credit_App_Selection__c,
                                Customer_Account__c,
                                Decision_Maker__c,
                                Description,
                                Description_downpayment__c,
                                Description_Loss_Pool__c,
                                Description_Other__c,
                                Description_term__c,
                                Description_URA__c,
                                Disabled_Calculation_Params__c,
                                Discount,
                                Downpayment__c,
                                Email,
                                End_User__c,
                                Expiration_Date__c,
                                ExpirationDate,
                                Fax,
                                Finance_Term_Month__c,
                                Financed_Amount__c,
                                Frequency__c,
                                Future_Value__c,
                                GrandTotal,
                                Id,
                                Include_In_Proposal__c,
                                Insurance_Amount__c,
                                Insurance_Display_Options__c,
                                Interest__c,
                                Is_Primary__c,
                                IsDeleted,
                                IsSyncing,
                                ITAD_Category__c,
                                ITAD_Fee__c,
                                LastModifiedById,
                                LastModifiedDate,
                                LastReferencedDate,
                                LastViewedDate,
                                Lease_Type__c,
                                LineItemCount,
                                Location_ID__c,
                                Manual_Decision__c,
                                Name,
                                Nominal_Interest_Rate__c,
                                OpportunityId,
                                Option_Number__c,
                                OwnerId,
                                Owner.Type,
                                Owner.Name,
                                Owner.FirstName,
                                Owner.LastName,
                                Partner_Sales_Rep__c,
                                Payment_Frequency__c,
                                Payment_Timing__c,
                                Phone,
                                Pricebook2Id,
                                Program__c,
                                Program_ID__c,
                                Quote_Number__c,
                                Quote_Rate__c,
                                QuoteNumber,
                                QuoteToAddress,
                                QuoteToCity,
                                QuoteToCountry,
                                QuoteToGeocodeAccuracy,
                                QuoteToLatitude,
                                QuoteToLongitude,
                                QuoteToName,
                                QuoteToPostalCode,
                                QuoteToState,
                                QuoteToStreet,
                                Rate_Type__c,
                                Rate_Type_Id__c,
                                Recalculation__c,
                                RecordTypeId,
                                Reference__c,
                                Rent_Per_Month__c,
                                Rental_Amount__c,
                                Residual__c,
                                Revenue__c,
                                ShippingAddress,
                                ShippingCity,
                                ShippingCountry,
                                ShippingGeocodeAccuracy,
                                ShippingHandling,
                                ShippingLatitude,
                                ShippingLongitude,
                                ShippingName,
                                ShippingPostalCode,
                                ShippingState,
                                ShippingStreet,
                                SmartComm_Docs_Count__c,
                                Status,
                                Status_Priority__c,
                                Subsidy_Rate_Type_Id__c,
                                Subtotal,
                                SystemModstamp,
                                Tax,
                                Term__c,
                                Total_Payment__c,
                                Total_Price__c,
                                TotalPrice,
                                Type_downpayment__c,
                                Type_Loss_Pool__c,
                                Type_Other__c,
                                Type_term__c,
                                Type_URA__c,
                                Use_Subsidy__c,
                                Valid_From__c,
                                Valid_To__c,
                                Value_downpayment__c,
                                Value_Loss_Pool__c,
                                Value_Other__c,
                                Value_term__c,
                                Value_URA__c        
                            FROM
                            Quote
                            where opportunityId = :sourceOppId 
                            and Current_Credit_App_Selection__c = true
                            ];
        }
        
         system.debug('running for opp is: ' + destinationOppId + ' selecting from :' + q.opportunityId);

         //move all quotes to selecting from opportunity id
             
        List<Quote_Line__c> qLineList = [SELECT
                                            Annual_Hours__c,
                                            Asset_Condition__c,
                                            Asset_Type__c,
                                            Asset_Type_ITA_Class__c,
                                            Asset_Type_ITA_Class_Id__c,
                                            Base_Unit_Sales_Price__c,
                                            Battery_Included__c,
                                            Billed_Residual_Amount__c,
                                            Booked_Residual_Amount__c,
                                            CreatedById,
                                            CreatedDate,
                                            CurrencyIsoCode,
                                            Equipment_Type__c,
                                            Id,
                                            IsDeleted,
                                            LastActivityDate,
                                            LastModifiedById,
                                            LastModifiedDate,
                                            Make__c,                                        
                                            Make_Id__c,
                                            Mast_Type__c,
                                            Model__c,
                                            Model_Id__c,
                                            MSRP__c,
                                            Name,
                                            Number_of_Units__c,
                                            Operating_Environment__c,
                                            Payment_Amount__c,
                                            Quote__c,
                                            Related_Asset__c,
                                            Subsidy__c,
                                            Subsidy_ID__c,
                                            SystemModstamp,
                                            Total_Sales_Price_Base__c
                                        FROM
                                        Quote_Line__c
                                        where quote__c = :q.id
                                        ] ;

        
        system.debug('quote id is: ' + q.id);
        q.id = null;
        Quote qClone = q;
        qClone.opportunityId = destinationOppId;
        qClone.option_number__c = 1;
        qClone.is_primary__c = false;
        qClone.is_appeal__c = true;
        qClone.Include_In_Proposal__c = true;
        qClone.Current_Credit_App_Selection__c = true;
        

        insert qClone;

        Map<String,ID> lineNameMap = new Map<String,ID>();

        for (Quote_Line__c ql:qLineList){
            ql.id = null;
            ql.quote__c = qClone.id;
            
        }

        
        List<Quote_Line__c> qLineListClone = qLineList;
    
            
        if (!qLineListClone.isEmpty()){
            insert qLineListClone;
        }

        Map<String,ID> newLineNameMap = new Map<String,ID>();

        for (Quote_Line__c ql:qLineListClone){
            if (ql.related_asset__c == null){
                newLineNameMap.put(ql.name,ql.id);
            }
        }

        //now i have a map with 
        //   Catepillar 2EP10000, new line id
        //   Catepillar 2EP10001, new line id

        List<Quote_Line__c> qLineListNew = [SELECT
                            Related_Asset__r.name
                            FROM
                            Quote_Line__c
                            where quote__c = :q.id
                            and related_asset__c != null
                            ] ;

        for (Quote_Line__c qlc:qLineListNew){
            qlc.related_asset__c = newLineNameMap.get(qlc.Related_Asset__r.name);
        }

        system.debug('map is: ' + newLineNameMap);

        if (!qLineListNew.isEmpty())
            update qLineListNew;

                                        
        Opportunity o = [select id from Opportunity where id = :destinationOppId];
        o.Originating_Quote_No__c = q.quote_number__c;
        update o;

        return '1';


    }
}