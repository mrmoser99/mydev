/**
 * @create: by Traction Team on 04/27/2020
 * added insertContractTeamMember method : DLL on demand PBI:640593: Geetha Bharadwaj
 * commenting the logic for Apex sharing - Geetha
 */
/**********************************************************************************************************
Class :  CustomContractTriggerHelper
Description : Helper Class for (Custom) Contract object.

Date/Sprint		PBI/Description
PI-22-Q4-20		870367 - Brazil Contract Not being assigned correct Business Unit
PI-22-Q4-22		845477 - Solution design for holistic authorization model (Dibyendu  11/16/2022)
  
***********************************************************************************************************/
public class CustomContractTriggerHelper {
    public static String BUSINESSDESC_CTI = 'Construction, Transportation & Infrastructure (CTI)';//Added as a part of change for PBI 845477
    public static void helpBeforeInsert(List<Contract__c> newContracts){
        setInitialValues(newContracts);
        setAccAndEndUser(newContracts);
        setOpportunity(newContracts);
        setProgram(newContracts);
        setShareWithAccount(newContracts);   //Added as a part of change for PBI 845477
    }
    
    public static void helpAfterInsert(Map<Id, Contract__c> newContractMap){
        updateOpportunity(newContractMap.values());
        updateAccRelation(newContractMap.values());
       /* //PBI:640593:DLLonDemand:When contract is inserted, it need to be inserted into ContractTeamMember obj 
        insertContractTeamMember(newContractMap.values());*/
    }
    
    // Start of Code for change PBI-845477  
    // - If the opp record type is or becomes retail and Business Unit Description is Construction, Transportation & Infrastructure (CTI), then populate the share_with_account__c value;
    public static void setShareWithAccount(List<Contract__c> contracts){
        List<Program__c> directPrograms = Database.query('select id,name,Sales_Channel__c from Program__c');
        Map<String, String> mapProgram = new Map<String, String>();
        for (Program__c directProgramRec : directPrograms ) {
            mapProgram.put(directProgramRec.name,directProgramRec.Sales_Channel__c);
			}
        List<Contract__c> contractsWithOutOpp = new List<Contract__c>();
		List<String> oppNos = new List<String>();
        for(Contract__c c : contracts){
            if(String.isNotBlank(c.UNQ_Opportunity__c)) {
                oppNos.add(c.UNQ_Opportunity__c);
            }
        }
        Map<String, Opportunity> retailConOpp = new Map<String, Opportunity>();
        for(Opportunity opp : [SELECT  Id, UNQ_Opportunity__c,RecordType.DeveloperName
                                   FROM    Opportunity
                                   WHERE   RecordType.DeveloperName='Retail' and UNQ_Opportunity__c IN: oppNos
                                  ])
            {
                retailConOpp.put(opp.UNQ_Opportunity__c, opp);
            }
        
        for(Contract__c c : contracts){
            if(c.Business_Unit_Description__c==BUSINESSDESC_CTI){
                /*if(String.isBlank(c.UNQ_Opportunity__c) && mapProgram.get(c.UNQ_Program__c)=='Direct' && c.Account__c!=null) {
                	c.Share_With_Account__c = c.Account__c;
            	}
            	else*/ 
                if(String.isNotBlank(c.UNQ_Opportunity__c)){
                   // if((retailConOpp.containsKey(c.UNQ_Opportunity__c) || mapProgram.get(c.UNQ_Program__c)=='Direct') && c.Account__c!=null){
                    if((retailConOpp.containsKey(c.UNQ_Opportunity__c)) && c.Account__c!=null){
                        c.Share_With_Account__c = c.Account__c;
                    }
            	}
            }
        }
    }
    // End of Code for change PBI-845477
    
    public static void setInitialValues(List<Contract__c> contracts){
        for(Contract__c c : contracts){
            if(String.isBlank(c.Source_System__c)){
                c.Source_System__c = 'GDW_Wayne';
            }
        }
    }
    
    public static void setAccAndEndUser(List<Contract__c> contracts){
        Set<String> vendorNos = new Set<String>();
        Set<String> customerCodes = new Set<String>();
        
        List<Contract__c> contractsWithVendor = new List<Contract__c>();
        List<Contract__c> contractsWithCustomer = new List<Contract__c>();
        
        for(Contract__c c : contracts){
            if(String.isBlank(c.Account__c) && String.isNotBlank(c.UNQ_Vendor__c)) {
                vendorNos.add(c.UNQ_Vendor__c);
                contractsWithVendor.add(c);
            }
            if(String.isBlank(c.End_User__c) && String.isNotBlank(c.UNQ_Customer__c)) {
                customerCodes.add(c.UNQ_Customer__c);
                contractsWithCustomer.add(c);
            }
        }
        
        if(contractsWithVendor.size() > 0 || contractsWithCustomer.size() > 0){
            Map<String, System_ID__c> sysIdByVendor = new Map<String, System_ID__c>();
            Map<String, System_ID__c> sysIdByCustomer = new Map<String, System_ID__c>();
            
            for(System_ID__c sysId : [SELECT  Id, Account__c, UNQ_Vendor__c, UNQ_Customer__c
                                      FROM    System_ID__c
                                      WHERE   UNQ_Vendor__c IN: vendorNos
                                      OR UNQ_Customer__c IN: customerCodes
                                     ])
            {
                if(String.isNotBlank(sysId.UNQ_Vendor__c) && sysId.UNQ_Vendor__c!=null) {
                    sysIdByVendor.put(sysId.UNQ_Vendor__c, sysId);
                }
                if(String.isNotBlank(sysId.UNQ_Customer__c)) {
                    sysIdByCustomer.put(sysId.UNQ_Customer__c, sysId);
                }
            }
            
            if(contractsWithVendor.size() > 0){
                for(Contract__c c : contractsWithVendor){
                    //PBI:635532:Contract Trigger modified: error when uploading bulk contract data 
                    if(sysIdByVendor.containskey(c.UNQ_Vendor__c)){
                        System_ID__c sysId = sysIdByVendor.get(c.UNQ_Vendor__c);
                       // if(sysId != null) {
                            c.Account__c = sysId.Account__c;
                            c.Vendor_ID__c = sysId.Id;
                      //  }   
                    }
                }
            }
            
            if(contractsWithCustomer.size() > 0){
                for(Contract__c c : contractsWithCustomer){
                    //PBI:635532:Contract Trigger modified: error when uploading bulk contract data 
                    if(sysIdByCustomer.containskey(c.UNQ_Customer__c)){
                        System_ID__c sysId = sysIdByCustomer.get(c.UNQ_Customer__c);
                        //if(sysId != null) {
                            c.End_User__c = sysId.Account__c;
                            c.Customer_Code__c = sysId.Id;
                       // }
                    }  
                }
            }
        }
    }
    
    public static void setOpportunity(List<Contract__c> contracts){
        Set<String> oppNos = new Set<String>();
        
        List<Contract__c> contractsWithOpp = new List<Contract__c>();
        
        for(Contract__c c : contracts){
            if(String.isNotBlank(c.UNQ_Opportunity__c)) {
                oppNos.add(c.UNQ_Opportunity__c);
                contractsWithOpp.add(c);
            }
        }
        
        if(contractsWithOpp.size() > 0){
            
            Map<String, Opportunity> oppByUNQ = new Map<String, Opportunity>();
            
            for(Opportunity opp : [SELECT  Id, UNQ_Opportunity__c
                                   FROM    Opportunity
                                   WHERE   UNQ_Opportunity__c IN: oppNos
                                  ])
            {
                oppByUNQ.put(opp.UNQ_Opportunity__c, opp);
            }
            if(oppByUNQ != null && !oppByUnQ.isEmpty()){
                for(Contract__c c : contractsWithOpp){
                    if(oppByUNQ.containsKey(c.UNQ_Opportunity__c)) {
                        Opportunity opp = oppByUNQ.get(c.UNQ_Opportunity__c);
                        c.Opportunity__c = opp.Id;
                    }
                }
            }
        }
    }
    
    public static void setProgram(List<Contract__c> contracts){
        Set<String> vpNos = new Set<String>();

        List<Contract__c> contractsWithProgram = new List<Contract__c>();
		List<Business_Unit__c> unknownBusinessUnit = [SELECT Id, Name FROM Business_Unit__c Where Name = 'Unknown'];
        List<Region__c> unknownRegion= [SELECT Id, Name FROM Region__c Where Name = 'Unknown'];
         List<Contract__c> contractsWhereRD_and_BUDIsNotBlank = new List<Contract__c>();
        
        for(Contract__c c : contracts){
            if(String.isNotBlank(c.Region_Description__c) && String.isNotBlank(c.Business_Unit_Description__c )){
                contractsWhereRD_and_BUDIsNotBlank.add(c);
                if(String.isNotBlank(c.UNQ_Program__c)){
                    vpNos.add(c.UNQ_Program__c);
                	contractsWithProgram.add(c);
                }
            }
            else if(String.isBlank(c.Program__c) && String.isNotBlank(c.UNQ_Program__c) && String.isBlank(c.Region_Description__c) && String.isBlank(c.Business_Unit_Description__c )) {
                vpNos.add(c.UNQ_Program__c);
                contractsWithProgram.add(c);
            }else{
                if(unknownRegion.size()>0){
                    c.Region__c = unknownRegion[0].Id;
                    c.Region_Description__c = unknownRegion[0].Name;
                }
                if(unknownBusinessUnit.size()>0){
                    c.Business_Unit__c = unknownBusinessUnit[0].Id;
                    c.Business_Unit_Description__c = unknownBusinessUnit[0].Name;
                    c.Legal_Entity_Description__c = '';
                }
            }
        }
        if(contractsWhereRD_and_BUDIsNotBlank.size()>0){
            setRegionRelationshipAndBusinessUnit(contractsWhereRD_and_BUDIsNotBlank);
        }
        if(contractsWithProgram.size() > 0){
            List<Program__c> programList = [
                    SELECT  Id, UNQ_Program__c,Region__c,Region_Description__c, 
                			Business_Unit__c,Business_Unit_Description__c,Legal_Entity_Description__c  
                    FROM    Program__c
                    WHERE   UNQ_Program__c IN: vpNos
            ];

            if(programList.size() > 0){
                Map<String, Program__c> mapOfUNQKeyToProgram = new Map<String, Program__c>();

                for(Program__c program : programList){
                    mapOfUNQKeyToProgram.put(program.UNQ_Program__c, program);
                }
               
                for(Contract__c c : contractsWithProgram){
                    Program__c program = mapOfUNQKeyToProgram.get(c.UNQ_Program__c);
                    if(program != null) {
                        c.Program__c = program.Id;
                        if(String.isBlank(c.Region_Description__c) && String.isBlank(c.Business_Unit_Description__c )){                          
                            c.Region__c = program.Region__c;
                            c.Region_Description__c = program.Region_Description__c;
                            c.Business_Unit__c = program.Business_Unit__c;
                            c.Business_Unit_Description__c = Program.Business_Unit_Description__c;
                            c.Legal_Entity_Description__c = program.Legal_Entity_Description__c;   
                        }
                    }
                }               
            }
        }
    }
	//PBI:446089:Contracts- Set Authorization Attributes from Transaction: Geetha
    private static void setRegionRelationshipAndBusinessUnit(List<Contract__c> contracts) {
        Map<String,String> mapOfRegionDescriptionToRegionName = new Map<String,String>();
        Map<String,String> mapOfBUDescriptionToBUName = new Map<String,String>();
        for (Contract__c contract : contracts) {
            mapOfRegionDescriptionToRegionName.put(contract.Region_Description__c,null);
            //870367 - Added comma check to avoid assigning 'Unknown' value to CTI Business Unit
            if(contract.Business_Unit_Description__c.containsIgnoreCase(',')){
				List<String> splitBU = contract.Business_Unit_Description__c.split(',');
                contract.Business_Unit_Description__c = '';
                for(String str: splitBU){
                    contract.Business_Unit_Description__c = contract.Business_Unit_Description__c+str;
                }                
            }
            mapOfBUDescriptionToBUName.put(contract.Business_Unit_Description__c,null);
        }
        mapOfRegionDescriptionToRegionName.put('Unknown','Unknown');
        mapOfBUDescriptionToBUName.put('Unknown','Unknown');
        for(Business_Unit_Association_Index__mdt objBUAI:[SELECT Id, Business_Unit_Attribute__c, Business_Unit_Name__c 
                                                          FROM Business_Unit_Association_Index__mdt 
                                                          WHERE Business_Unit_Attribute__c in : mapOfBUDescriptionToBUName.keyset()]){
        	mapOfBUDescriptionToBUName.put(objBUAI.Business_Unit_Attribute__c,objBUAI.Business_Unit_Name__c); 
        }
        
        Map<String, Business_Unit__c> mapOfBUs = new Map<String,Business_Unit__c>();   
        Map<String, Business_Unit__c> mapOfBUWithLE = new Map<String,Business_Unit__c>();
        for(Business_Unit__c bu : [SELECT Id,Name,Parent_Business_Unit__r.Name 
                                   FROM Business_Unit__c 
                                   WHERE Name in : mapOfBUDescriptionToBUName.values() ]){
                                       mapOfBUs.put(bu.Name, bu);
                                       mapOfBUWithLE.put(bu.Name+bu.Parent_Business_Unit__r.Name, bu);
                                   }
        
        for(Region_Association_Index__mdt objRegionAssociationIndex : [SELECT Geographic_Attribute__c,Region_Name__c 
                                                                       FROM Region_Association_Index__mdt 
                                                                       WHERE Geographic_Attribute__c in :mapOfRegionDescriptionToRegionName.keySet()]){
            mapOfRegionDescriptionToRegionName.put(objRegionAssociationIndex.Geographic_Attribute__c,objRegionAssociationIndex.Region_Name__c);
        }
        
        Map<String, Region__c> mapOfRegions = new Map<String,Region__c>();            
        for(Region__c region : [SELECT Id, Name FROM Region__c where Name in : mapOfRegionDescriptionToRegionName.values() ]){
            mapOfRegions.put(region.Name, region);
        }
        
        for (Contract__c contract : contracts) {
            
            if(mapOfRegionDescriptionToRegionName.containsKey(contract.Region_Description__c) && mapOfRegionDescriptionToRegionName.get(contract.Region_Description__c) != null){
                contract.Region_Description__c = mapOfRegions.get(mapOfRegionDescriptionToRegionName.get(contract.Region_Description__c)).Name;
                contract.Region__c = mapOfRegions.get(mapOfRegionDescriptionToRegionName.get(contract.Region_Description__c)).Id;
            }else if(mapOfRegionDescriptionToRegionName.containsKey('Unknown')){
                contract.Region_Description__c = mapOfRegions.get(mapOfRegionDescriptionToRegionName.get('Unknown')).Name;
                contract.Region__c = mapOfRegions.get(mapOfRegionDescriptionToRegionName.get('Unknown')).Id;
            }
            if(mapOfBUDescriptionToBUName.containsKey(contract.Business_Unit_Description__c)  && mapOfBUDescriptionToBUName.get(contract.Business_Unit_Description__c) !=null){
                contract.Business_Unit__c = mapOfBUs.get(mapOfBUDescriptionToBUName.get(contract.Business_Unit_Description__c)).Id;
                 contract.Business_Unit_Description__c = mapOfBUs.get(mapOfBUDescriptionToBUName.get(contract.Business_Unit_Description__c)).Name;
               /* If((mapOfBUs.get(mapOfBUDescriptionToBUName.get(contract.Business_Unit_Description__c)).Parent_Business_Unit__r != null) && String.isBlank(contract.Legal_Entity_Description__c)){
                  //  contract.Legal_Entity_Description__c = mapOfBUs.get(mapOfBUDescriptionToBUName.get(contract.Business_Unit_Description__c)).Parent_Business_Unit__r.Name;
                }else */
                if(!String.isBlank(contract.Legal_Entity_Description__c) && mapOfBUDescriptionToBUName.containsKey(contract.Business_Unit_Description__c)
                     && mapOfBuWithLE.containsKey(mapOfBUDescriptionToBUName.get(contract.Business_Unit_Description__c)+contract.Legal_Entity_Description__c)){
                     contract.Legal_Entity_Description__c = mapOfBuWithLE.get(mapOfBUDescriptionToBUName.get(contract.Business_Unit_Description__c)+contract.Legal_Entity_Description__c).Parent_Business_Unit__r.Name;
                }else if(!String.isBlank(contract.Legal_Entity_Description__c) && mapOfBUDescriptionToBUName.containsKey(contract.Business_Unit_Description__c)
                     && !mapOfBuWithLE.containsKey(mapOfBUDescriptionToBUName.get(contract.Business_Unit_Description__c)+contract.Legal_Entity_Description__c)){
                     contract.Legal_Entity_Description__c = '';
                }
               
            }else if(mapOfBUDescriptionToBUName.containsKey('Unknown')){
                contract.Business_Unit__c = mapOfBUs.get(mapOfBUDescriptionToBUName.get('Unknown')).Id;
                contract.Business_Unit_Description__c = mapOfBUs.get(mapOfBUDescriptionToBUName.get('Unknown')).Name;
                contract.Legal_Entity_Description__c = '';
            }
        }
    }
    
    public static void updateOpportunity(List<Contract__c> contracts){
        Map<Id, Contract__c> contractByOppId = new Map<Id, Contract__c>();

        for(Contract__c c : contracts){
            if(c.Opportunity__c != null){
                contractByOppId.put(c.Opportunity__c, c);
            }
        }

        if(contractByOppId.size() > 0){
            List<Opportunity> opps = [
                    SELECT  Id, Contract__c, CloseDate
                    FROM    Opportunity
                    WHERE   Id IN: contractByOppId.keySet()
                    FOR UPDATE
            ];

            if(opps.size() > 0){
                List<Opportunity> oppsForUpdate = new List<Opportunity>();

                for(Opportunity opp : opps){
                    oppsForUpdate.add(new Opportunity(
                            Id = opp.Id,
                            Contract__c = contractByOppId.get(opp.Id).Id
                    ));
                }

                if(oppsForUpdate.size() > 0){
                    update oppsForUpdate;
                }
            }
        }
    }
    
    public static void updateAccRelation(List<Contract__c> contracts){
        Map<Id, Contract__c> contractByOppId = new Map<Id, Contract__c>();

        for(Contract__c c : contracts){
            if(c.Opportunity__c != null){
                contractByOppId.put(c.Opportunity__c, c);
            }
        }

        if(contractByOppId.size() > 0){
            List<Related_Account__c> accRelations = [
                    SELECT  Contract__c, Opportunity__c
                    FROM    Related_Account__c
                    WHERE   Opportunity__c IN: contractByOppId.keySet()
                    FOR UPDATE
            ];

            if(accRelations.size() > 0){
                List<Related_Account__c> accRelationsToUpdate = new List<Related_Account__c>();

                for(Related_Account__c accRelation : accRelations){
                    Contract__c c = contractByOppId.get(accRelation.Opportunity__c);
                    if(accRelation.Contract__c != c.Id ){
                    
                    accRelationsToUpdate.add(new Related_Account__c(
                                    Id = accRelation.Id,
                                    Contract__c = c.Id
                            ));
                    }
                }

                if(accRelationsToUpdate.size() > 0){
                    update accRelationsToUpdate;
                }
            }
        }
    }
    
  /*  //PBI:640593:DLLonDemand:When contract is inserted, it need to be inserted into ContractTeamMember obj 
    public static void insertContractTeamMember(List<Contract__c> newContracts){
        String partnerAdmin = System.label.ddPartnerAdminProfile;
        Set<Id> accountIdset = new Set<Id>();
        List<Contract_team__c> contractTMList = new List<Contract_team__c>();
        List<AccountShare> accountShareList = new List<AccountShare>();
        
        for(Contract__c cont: newContracts){
            if(cont.Account__c != null ){
                accountIdset.add(cont.Account__c);
            }
             if(cont.End_User__c != null ){
                accountIdset.add(cont.End_User__c);
            }
            
        }
        
        if(accountIdset != null){
            List<User> uslist = [Select Id, ContactId,Contact.AccountId,Name from User where ContactId in: ([Select Id from Contact  Where AccountId in: accountIdset]) AND Profile.Name = :partnerAdmin ];
            
            if(!uslist.isEmpty()){
                for(Contract__c cont: newContracts){
                    for(User us: uslist){
                        //Sharing both Account and Enduser account to the Partner Admin user
                        //PBI:665016:Portfolio Team - End User Visibility Enable:Share Enduser account to Partner Admin
                        if((cont.Account__c == us.Contact.AccountId)){
                          // (cont.End_User__c == us.Contact.AccountId) 
                          
                            Contract_team__c contTeam = new Contract_team__c();
                            contTeam.Name =  us.Name;
                            contTeam.Contract__c = cont.id;
                            contTeam.Contract_Access__c = 'Read';
                            //contTeam.Team_Role__c = 'Partner Admin';
                            contTeam.Team_Role__c = partnerAdmin;
                            contTeam.User__c = us.Id;
                            contractTMList.add(contTeam);
                        } 
                        //Share enduser account
                      //  if( (cont.End_User__c == us.Contact.AccountId)){
                         //   AccountShare actShare = new AccountShare();
                        //    actShare.AccountId = us.Contact.AccountId;
                        //    actShare.AccountAccessLevel = 'read';
                         //   actShare.OpportunityAccessLevel = 'read';
                        //    actShare.CaseAccessLevel = 'read';
                           // actShare.ContactAccessLevel = 'read';
                         //   actShare.UserOrGroupId = us.Id;
                          //
                          //  accountShareList.add(actShare);
                      //  }
                    } 
                    
                } 
                if (!contractTMList.isEmpty()){
                    insert contractTMList;
                }
               // if(!accountShareList.isEmpty()){
                   // insert accountShareList;
              //  }
            }
        }
    }*/
}