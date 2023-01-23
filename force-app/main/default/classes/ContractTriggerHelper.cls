/*
 * Author:          Samuel Meyers
 * Creation Date:   3/27/19
 *
 * Notes: Cleanup/simplification of ContractTriggerHandler
 */
public class ContractTriggerHelper{

    public static void helpBeforeInsert(List<Contract> newContracts){
        setInitialValues(newContracts);
        setAccAndEndUser(newContracts);
        setOpportunity(newContracts);
        setVendorProgram(newContracts);
    }

    public static void helpAfterInsert(Map<Id, Contract> newContractMap){
        updateOpportunity(newContractMap.values());
        updateOppRelation(newContractMap.values());
        activateContracts(newContractMap.values());
    }

    public static void helpBeforeUpdate(Map<Id, Contract> oldContractMap, Map<Id, Contract> newContractMap){
        statusChange(oldContractMap, newContractMap);
    }


    public static void setInitialValues(List<Contract> contracts){
        for(Contract c : contracts){
            if(String.isBlank(c.Source_System__c)){
                c.Source_System__c = 'GDW_Wayne';
                c.Location__c = 'United States';
                c.Contract_Number__c = c.UNQ_Contract__c;
                c.CurrencyIsoCode = 'USD';
            }
        }
    }

    public static void setAccAndEndUser(List<Contract> contracts){
        Set<String> vendorNos = new Set<String>();
        Set<String> customerCodes = new Set<String>();

        List<Contract> contractsWithVendor = new List<Contract>();
        List<Contract> contractsWithCustomer = new List<Contract>();

        for(Contract c : contracts){
            if(String.isBlank(c.AccountId) && String.isNotBlank(c.UNQ_Vendor__c)) {
                vendorNos.add(c.UNQ_Vendor__c);
                contractsWithVendor.add(c);
            }
            if(String.isBlank(c.End_User__c) && String.isNotBlank(c.UNQ_Customer__c)) {
                customerCodes.add(c.UNQ_Customer__c);
                contractsWithCustomer.add(c);
            }
        }

        if(contractsWithVendor.size() > 0 || contractsWithCustomer.size() > 0){
            List<System_ID__c> sysIds = [
                    SELECT  Id, Account__c, UNQ_Vendor__c, UNQ_Customer__c
                    FROM    System_ID__c
                    WHERE   UNQ_Vendor__c IN: vendorNos
                            OR UNQ_Customer__c IN: customerCodes
            ];

            if(sysIds.size() > 0){
                Map<String, System_ID__c> sysIdByVendor = new Map<String, System_ID__c>();
                Map<String, System_ID__c> sysIdByCustomer = new Map<String, System_ID__c>();

                for(System_ID__c sysId : sysIds){
                    if(String.isNotBlank(sysId.UNQ_Vendor__c) && sysId.UNQ_Vendor__c!=null) {
                        sysIdByVendor.put(sysId.UNQ_Vendor__c, sysId);
                    }
                    if(String.isNotBlank(sysId.UNQ_Customer__c)) {
                        sysIdByCustomer.put(sysId.UNQ_Customer__c, sysId);
                    }
                }

                if(contractsWithVendor.size() > 0){
                    for(Contract c : contractsWithVendor){
                        System_ID__c sysId = sysIdByVendor.get(c.UNQ_Vendor__c);
                        if(sysId != null) {
                            c.AccountId = sysId.Account__c;
                            c.Vendor_ID__c = sysId.Id;
                        }
                    }
                }

                if(contractsWithCustomer.size() > 0){
                    for(Contract c : contractsWithCustomer){
                        System_ID__c sysId = sysIdByCustomer.get(c.UNQ_Customer__c);
                        if(sysId != null) {
                            c.End_User__c = sysId.Account__c;
                            c.Customer_Code__c = sysId.Id;
                        }
                    }
                }
            }
        }
    }

    public static void setOpportunity(List<Contract> contracts){
        Set<String> oppNos = new Set<String>();

        List<Contract> contractsWithOpp = new List<Contract>();

        for(Contract c : contracts){
            if(String.isNotBlank(c.UNQ_Opportunity__c)) {
                oppNos.add(c.UNQ_Opportunity__c);
                contractsWithOpp.add(c);
            }
        }

        if(contractsWithOpp.size() > 0){
            List<Opportunity> opps = [
                    SELECT  Id, UNQ_Opportunity__c
                    FROM    Opportunity
                    WHERE   UNQ_Opportunity__c IN: oppNos
            ];

            if(opps.size() > 0){
                Map<String, Opportunity> oppByUNQ = new Map<String, Opportunity>();

                for(Opportunity opp : opps){
                    oppByUNQ.put(opp.UNQ_Opportunity__c, opp);
                }

                for(Contract c : contractsWithOpp){
                    Opportunity opp = oppByUNQ.get(c.UNQ_Opportunity__c);
                    if(opp != null) {
                        c.Opportunity__c = opp.Id;
                    }
                }
            }
        }
    }

    public static void setVendorProgram(List<Contract> contracts){
        Set<String> vpNos = new Set<String>();

        List<Contract> contractsWithVP = new List<Contract>();

        for(Contract c : contracts){
            if(String.isNotBlank(c.UNQ_Vendor_Program__c)) {
                vpNos.add(c.UNQ_Vendor_Program__c);
                contractsWithVP.add(c);
            }
        }

        if(contractsWithVP.size() > 0){
            List<Vendor_Program__c> vps = [
                    SELECT  Id, UNQ_Vendor_Program__c
                    FROM    Vendor_Program__c
                    WHERE   UNQ_Vendor_Program__c IN: vpNos
            ];

            if(vps.size() > 0){
                Map<String, Vendor_Program__c> vpByUNQ = new Map<String, Vendor_Program__c>();

                for(Vendor_Program__c vp : vps){
                    vpByUNQ.put(vp.UNQ_Vendor_Program__c, vp);
                }

                for(Contract c : contractsWithVP){
                    Vendor_Program__c vp = vpByUNQ.get(c.UNQ_Vendor_Program__c);
                    if(vp != null) {
                        c.Vendor_Program__c = vp.Id;
                    }
                }
            }
        }
    }

    public static void activateContracts(List<Contract> contracts){
        List<Contract> contractsToActivate = new List<Contract>();

        for(Contract c : contracts){
            if(c.Status != null && String.isNotBlank(c.Status__c)){
                contractsToActivate.add(new Contract(
                        Id = c.Id,
                        Status = c.Status__c
                ));
            }
        }

        if(contractsToActivate.size() > 0){
            update contractsToActivate;
        }
    }

    public static void updateOppRelation(List<Contract> contracts){
        Map<Id, Contract> contractByOppId = new Map<Id, Contract>();

        for(Contract c : contracts){
            if(c.Opportunity__c != null){
                contractByOppId.put(c.Opportunity__c, c);
            }
        }

        if(contractByOppId.size() > 0){
            List<Opportunity_Relationship__c> oppRelations = [
                    SELECT  Contract__c, Opportunity__c, Opportunity_Role__c
                    FROM    Opportunity_Relationship__c
                    WHERE   Opportunity__c IN: contractByOppId.keySet()
                    FOR UPDATE
            ];

            if(oppRelations.size() > 0){
                List<Opportunity_Relationship__c> oppRelationsToUpdate = new List<Opportunity_Relationship__c>();

                for(Opportunity_Relationship__c oppRelation : oppRelations){
                    Contract c = contractByOppId.get(oppRelation.Opportunity__c);
                    if(c != null){
                        Boolean hasAccOrEndUser = String.isNotBlank(c.AccountId) || String.isNotBlank(c.End_User__c);
                        Boolean isVendorOrEndUser = oppRelation.Opportunity_Role__c == 'Vendor' || oppRelation.Opportunity_Role__c=='End User';

                        if(hasAccOrEndUser && isVendorOrEndUser){
                            oppRelationsToUpdate.add(new Opportunity_Relationship__c(
                                    Id = oppRelation.Id,
                                    Contract__c = c.Id
                            ));
                        }
                    }
                }

                if(oppRelationsToUpdate.size() > 0){
                    update oppRelationsToUpdate;
                }
            }
        }
    }

    public static void updateOpportunity(List<Contract> contracts){
        Map<Id, Contract> contractByOppId = new Map<Id, Contract>();

        for(Contract c : contracts){
            if(c.Opportunity__c != null){
                contractByOppId.put(c.Opportunity__c, c);
            }
        }

        if(contractByOppId.size() > 0){
            List<Opportunity> opps = [
                    SELECT  Id, ContractId, CloseDate
                    FROM    Opportunity
                    WHERE   Id IN: contractByOppId.keySet()
                    FOR UPDATE
            ];

            if(opps.size() > 0){
                List<Opportunity> oppsForUpdate = new List<Opportunity>();

                for(Opportunity opp : opps){
                    oppsForUpdate.add(new Opportunity(
                            Id = opp.Id,
                            ContractId = contractByOppId.get(opp.Id).Id
                    ));
                }

                if(oppsForUpdate.size() > 0){
                    update oppsForUpdate;
                }
            }
        }
    }

    public static void statusChange(Map<Id, Contract> oldContractById, Map<Id, Contract> newContractById){
        for(Contract newCont : newContractById.values()) {
            Contract oldCont = oldContractById.get(newCont.Id);

            if(oldCont.Status__c != newCont.Status__c && newCont.Status != newCont.Status__c){
                newCont.Status = newCont.Status__c;
            }
        }
    }
}