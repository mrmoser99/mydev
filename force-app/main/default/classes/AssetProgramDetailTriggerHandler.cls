/**
 * This class is used to provide more specialized behavior for DML operations for Asset program details records
 * @author Anujit (Cognizant)
 * @date 2021-05-05
 */
public with sharing class AssetProgramDetailTriggerHandler extends TriggerHandler {

    private static Boolean oldQuickCalcProduct = false;
    
    /**
     * Override the parent class method
     */   
    public override void beforeInsert() {

        validateAssetProgramDetailsProduct();
        validateQuickCalculationProduct();
    }

    public override void beforeUpdate() {
        validateQuickCalculationProduct();
    }

    /**
     * Method checks currency code. Product's Pricebook entry should exist in Standard Pricebook 
     * with the same CurrencyIsoCode as defined on the program
     */ 
    private void validateAssetProgramDetailsProduct() {
        Set<Id> productIds = new Set<Id>();
        Set<Id> assetProgramIds = new Set<Id>();

        Map<Id, Program__c> programMap = new Map<Id, Program__c>();

        for (Asset_Program_Detail__c eachAsset : (List<Asset_Program_Detail__c>) Trigger.new) {
            productIds.add(eachAsset.Product__c);
            assetProgramIds.add(eachAsset.Asset_Program__c);
        }

        // get pricebook entries
        List<PricebookEntry> pricebookEntries = new WoSSelector().getPriceBookEntry(productIds);

        Map<Id, Set<String>> product2IdToCurrencyIsoCodes = new Map<Id, Set<String>>();
        for (PricebookEntry pbe : pricebookEntries) {
            Set<String> currencyIsoCodes = new Set<String>();
            if (product2IdToCurrencyIsoCodes.containsKey(pbe.Product2Id)) {
                currencyIsoCodes = product2IdToCurrencyIsoCodes.get(pbe.Product2Id);
            }
            currencyIsoCodes.add(pbe.CurrencyIsoCode);
            product2IdToCurrencyIsoCodes.put(pbe.Product2Id, currencyIsoCodes);
        }

        //SOQL on program
        list<Program__c> programList = new WoSSelector().getProgramDetails(assetProgramIds);
        
        for(Program__c eachProgram : programList){
            programMap.put(eachProgram.Asset_Program__c,eachProgram);
        }
        
        //if program and product currencies dont match throw error
        for (Asset_Program_Detail__c assetDetails : (List<Asset_Program_Detail__c>) Trigger.new) {
            Program__c currentProgram = programMap.get(assetDetails.Asset_Program__c);
            if (!product2IdToCurrencyIsoCodes.containsKey(assetDetails.Product__c) ||
                !product2IdToCurrencyIsoCodes.get(assetDetails.Product__c).contains(currentProgram.CurrencyIsoCode)
            ) {
                assetDetails.addError(Label.opOfferCurrencyEQProductCurrency);
            }
        }
    }

    /**
     * Method checks if there is only one Quick Calculation Product for the Asset Program
     */ 
    private void validateQuickCalculationProduct() {
        if (oldQuickCalcProduct) {
            oldQuickCalcProduct = false;
        } else {
            oldQuickCalcProduct = false;
            Set<Id> assetProgramIds = new Set<Id>();
            Map<Id,Asset_Program_Detail__c> newAssetProgramByAssetDetailsId = new Map<Id,Asset_Program_Detail__c>();

            // Validate if we have few Quick Calculation Products for the same Asset Program among new records
            for (Asset_Program_Detail__c eachAsset : (List<Asset_Program_Detail__c>) Trigger.new) {
                assetProgramIds.add(eachAsset.Asset_Program__c);

                //skip iteration if it is not Quick Calculation Product
                if (!eachAsset.Quick_Calculation_Product__c) {
                    continue;
                }

                // show error message if there are more then one Quick Calculation Product for one Asset Program
                if (newAssetProgramByAssetDetailsId.get(eachAsset.Asset_Program__c) != null) {
                    eachAsset.addError(Label.Quick_Calculation_Product_Error);
                } else {
                    newAssetProgramByAssetDetailsId.put(eachAsset.Asset_Program__c, eachAsset);
                }
            }

            // get map with Asset Program records Id by Asset Program Id
            Map<Id,Asset_Program__c> assetProgramsById = new Map<Id,Asset_Program__c>(new WoSSelector().getAssetProgramDetails(assetProgramIds));
            List<Asset_Program_Detail__c> updatedAssetProgramDetails = new List<Asset_Program_Detail__c>();

            // Validate if we have few Quick Calculation Products for the same Asset Program among existing records
            for (Asset_Program_Detail__c assetDetails : (List<Asset_Program_Detail__c>) Trigger.new) {
                Asset_Program__c assetProgram = assetProgramsById.get(assetDetails.Asset_Program__c);
                Boolean assetProgramHasCalcProduct = false;

                // check existing Asset Program Detail records
                for (Asset_Program_Detail__c assetProgramDetail : assetProgram.Asset_Program_Details__r) {

                    // show error message if there are one existing and one new Quick Calculation Product for one Asset Program
                    if (assetDetails.Quick_Calculation_Product__c && assetProgramDetail.Quick_Calculation_Product__c && (assetDetails.Id != assetProgramDetail.Id)) {
                        //if new Quick Calculation product is selected 
                        assetProgramDetail.Quick_Calculation_Product__c = false;
                        updatedAssetProgramDetails.add(assetProgramDetail);
                        oldQuickCalcProduct = true;
                        assetProgramHasCalcProduct = true;
                    } else if (!assetDetails.Quick_Calculation_Product__c && assetProgramDetail.Quick_Calculation_Product__c && (assetDetails.Id != assetProgramDetail.Id)) {
                        assetProgramHasCalcProduct = true;
                    } else if (assetDetails.Quick_Calculation_Product__c && !assetProgramDetail.Quick_Calculation_Product__c) {
                        assetProgramHasCalcProduct = true;
                    }
                }

                // show error message if there is no Quick Calculation Product at all
                if (!assetDetails.Quick_Calculation_Product__c && assetProgramHasCalcProduct == false && (newAssetProgramByAssetDetailsId.get(assetDetails.Asset_Program__c) == null)) {
                    assetDetails.addError(Label.Quick_Calculation_Product_Error);
                }
            } 
            
            update updatedAssetProgramDetails;
        }
    }
    
    
    /**
     * Inner class-selector
     */
    public without sharing class WoSSelector {
        
        /**
        *Name: getPriceBookEntry
        *Purpose: query account region's ISO code from opportunity.  
        */
        private List<PricebookEntry> getPriceBookEntry(Set<Id> productIds) {            
            return [
                SELECT  Id, Product2Id, CurrencyIsoCode
                FROM    PricebookEntry
                WHERE   Product2Id IN :productIds AND Pricebook2.isStandard = true
            ];      
        }
        
        
        /**
        *Name: getProgramDetails
        *Purpose: query  Currency IsoCode from Program__c.  
        */
        private List<Program__c> getProgramDetails(Set<Id> assetProgramIds) {
           return [
                SELECT  Asset_Program__c, id, CurrencyIsoCode 
                FROM    Program__c 
                WHERE   Asset_Program__c IN: assetProgramIds];
        }

        /**
        *Name: getAssetProgramDetails
        *Purpose: query  Asset_Program__c records.  
        */
        private List<Asset_Program__c> getAssetProgramDetails(Set<Id> assetProgramIds) {
            return [
                SELECT  Id, (SELECT Id, Quick_Calculation_Product__c FROM Asset_Program_Details__r)
                FROM    Asset_Program__c
                WHERE   Id IN: assetProgramIds
            ];
        }
    }
}