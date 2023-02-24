/**
 * Created by Dibyendu on 02/02/2023.
 */
/**********************************************************************************************************
   Class :  DODWorkTableTriggerHelper
   Description : Helper Class for Opportunity

   Date/Sprint		PBI/Description
   PI-23-Q1-02		922613 - Modify Opp Trigger and Develop async process, worktable to Async update application and asset(Dibyendu)*/

public class DODAsyncUpdate implements Queueable {
    
    private List<DOD_API_Worktable__c> updateAssets;
    public DODAsyncUpdate(List<DOD_API_Worktable__c> updateAssetList){
        this.updateAssets = updateAssetList;
    }
    
    public void execute(QueueableContext context) {
       //List<DOD_API_Worktable__c> updateAssets  =   [select id,Asset_Base_Unit_Sales_Price__c,Asset_Model__c,Asset_Number_of_Units__c,Asset_Type__c,Update_Type__c,Updated__c,OpportunityID__c ,Application_Number__c from DOD_API_Worktable__c where Update_Type__c ='Assets' and Updated__c=false];
        List<Opportunity_Line_Item__c> updateLineItemList = new List<Opportunity_Line_Item__c>();
        List<Opportunity_Line_Item__c> insertLineItemList = new List<Opportunity_Line_Item__c>();
        List<DOD_API_Worktable__c> updateWorkTableList = new List<DOD_API_Worktable__c>();
        
        if(updateAssets.size()>0){
            for(DOD_API_Worktable__c asset:updateAssets){
                
                List<Opportunity_Line_Item__c> matchLineItem = [select id,Opportunity__c,Make__c,Model__c,Base_Unit_Sales_Price__c,Number_of_Units__c from Opportunity_Line_Item__c where Opportunity__c = :asset.OpportunityID__c and Model__c=:asset.Asset_Model__c and  Make__c = :asset.Asset_Brand__c];
               
                if(matchLineItem.size()>0){
                    Opportunity_Line_Item__c updateLineItem = new Opportunity_Line_Item__c();
                    updateLineItem.Base_Unit_Sales_Price__c = asset.Asset_Base_Unit_Sales_Price__c;
                    updateLineItem.Number_of_Units__c =  asset.Asset_Number_of_Units__c;
                    updateLineItem.id = matchLineItem[0].id;
                    updateLineItemList.add(updateLineItem);
                    
                    DOD_API_Worktable__c updateWorkTable = new DOD_API_Worktable__c();
                    updateWorkTable.Updated__c = true;
                    updateWorkTable.id=asset.id;
                    updateWorkTableList.add(updateWorkTable);                   
                }
                else{
                    Opportunity_Line_Item__c insertLineItem = new Opportunity_Line_Item__c();
                    
                }
            }
            
        }
        if(updateLineItemList.size()>0){
            update updateLineItemList;
            update updateWorkTableList;
            
        }    
        system.debug('DDT Update:'+updateLineItemList+updateWorkTableList);
    }

}