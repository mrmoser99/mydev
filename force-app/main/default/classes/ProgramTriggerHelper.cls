/**
 * @Created by Traction Team on 04/15/2020.
 */
public class ProgramTriggerHelper {
    public static void helpBeforeInsert(List<Program__c> newPrograms){
        setBusinessUnit(newPrograms);
        setRegion(newPrograms);
    }
    
    public static void helpBeforeUpdate(Map<Id,Program__c> oldProgramsMap, List<Program__c> newPrograms){
        List<Program__c> programsToUpdateBU = new List<Program__c>();
        List<Program__c> programsToUpdateRegion = new List<Program__c>();
        
        for(Program__c objProgram :newPrograms){
            Program__c oldProgram = oldProgramsMap.get(objProgram.Id);
            if(oldProgram.Business_Unit_Description__c != objProgram.Business_Unit_Description__c ||
                    oldProgram.Legal_Entity_Description__c != objProgram.Legal_Entity_Description__c){
                programsToUpdateBU.add(objProgram);
            }
            if(oldProgram.Region_Description__c != objProgram.Region_Description__c){
                programsToUpdateRegion.add(objProgram);
            }
        }
        setBusinessUnit(programsToUpdateBU);
        setRegion(programsToUpdateRegion);
    }
    
    public static void setRegion(List<Program__c> programs){
        Map<String, String> regions = new Map<String, String>();
        for(Region_Association_Index__mdt objRegion : [SELECT Id,Geographic_Attribute__c, Region_Name__c FROM Region_Association_Index__mdt]){
            regions.put(objRegion.Geographic_Attribute__c,objRegion.Region_Name__c);
        }
        regions.put('Unknown','Unknown');
        
        Map<String, Id> regionObjectRecords = new Map<String, Id>();
        for(Region__c objRegion : [SELECT Id,Name FROM Region__c where Name in : regions.values()]){
            regionObjectRecords.put(objRegion.Name,objRegion.Id);
        }
        
        for(Program__c objProgram : programs){
            if(regions.containsKey(objProgram.Region_Description__c) 
               && regionObjectRecords.containsKey(regions.get(objProgram.Region_Description__c))) {
                   objProgram.Region__c = regionObjectRecords.get(regions.get(objProgram.Region_Description__c));
                   objProgram.Region_Description__c = regions.get(objProgram.Region_Description__c);
               }else if(regionObjectRecords.containsKey('Unknown')){
                   objProgram.Region__c = regionObjectRecords.get('Unknown');
                   objProgram.Region_Description__c = 'Unknown';
               }
        }
    }
    
    public static void setBusinessUnit(List<Program__c> programs){
        Map<String, String> businessUnits = new Map<String, String>();
        for(Business_Unit_Association_Index__mdt objBusinessUnit : [SELECT Id,Business_Unit_Attribute__c,Business_Unit_Name__c FROM Business_Unit_Association_Index__mdt]){
            businessUnits.put(objBusinessUnit.Business_Unit_Attribute__c,objBusinessUnit.Business_Unit_Name__c);
        }
        businessUnits.put('Unknown','Unknown');
        Map<String, Business_Unit__c> businessUnitsRecords = new Map<String, Business_Unit__c>();
        Map<String, Map<String, Business_Unit__c>> businessUnitsRecordsByLeg = new Map<String, Map<String, Business_Unit__c>>();
        for(Business_Unit__c objBusinessUnit : [SELECT Id,Name,Parent_Business_Unit__r.Name FROM Business_Unit__c where Name in : businessUnits.values()]){
            businessUnitsRecords.put(objBusinessUnit.Name,objBusinessUnit);
            if (objBusinessUnit.Parent_Business_Unit__r.Name != null && businessUnitsRecordsByLeg.containsKey(objBusinessUnit.Parent_Business_Unit__r.Name)){
                businessUnitsRecordsByLeg.get(objBusinessUnit.Parent_Business_Unit__r.Name).put(objBusinessUnit.Name, objBusinessUnit);
            }else{
                businessUnitsRecordsByLeg.put(objBusinessUnit.Parent_Business_Unit__r.Name,new Map<String, Business_Unit__c>{objBusinessUnit.Name => objBusinessUnit });
            }
        }
        for(Program__c objProgram : programs){
            if(objProgram.Legal_Entity_Description__c != null && objProgram.Business_Unit_Description__c != null){
                String legName = businessUnits.get(objProgram.Legal_Entity_Description__c);
                String busDesc = businessUnits.get(objProgram.Business_Unit_Description__c);
                if(legName != null && busDesc != null && businessUnitsRecordsByLeg.containsKey(legName) && businessUnitsRecordsByLeg.get(legName).containsKey(busDesc)){
                    Business_Unit__c objBusinessUnit = businessUnitsRecordsByLeg.get(legName).get(busDesc);
                    objProgram.Business_Unit__c = objBusinessUnit.Id;
                    objProgram.Business_Unit_Description__c = businessUnits.get(objProgram.Business_Unit_Description__c);
                }else if(businessUnitsRecords.containsKey('Unknown')){
                    objProgram.Business_Unit__c = businessUnitsRecords.get('Unknown').Id;
                    objProgram.Business_Unit_Description__c = 'Unknown';
                }

            } else if(businessUnits.containsKey(objProgram.Business_Unit_Description__c)
               && businessUnitsRecords.containsKey(businessUnits.get(objProgram.Business_Unit_Description__c))) {
                   Business_Unit__c objBusinessUnit = businessUnitsRecords.get(businessUnits.get(objProgram.Business_Unit_Description__c));
                   objProgram.Business_Unit__c = objBusinessUnit.Id;
                   objProgram.Legal_Entity_Description__c = objBusinessUnit.Parent_Business_Unit__r == null? '':objBusinessUnit.Parent_Business_Unit__r.Name;
                   objProgram.Business_Unit_Description__c = businessUnits.get(objProgram.Business_Unit_Description__c);
               }else if(businessUnitsRecords.containsKey('Unknown')){
                   objProgram.Business_Unit__c = businessUnitsRecords.get('Unknown').Id;
                   objProgram.Business_Unit_Description__c = 'Unknown';
               }
        }
    }
}