public  class RecordTypeSelector{

    /*

     * This function will fetch the RecordTypes of

     * provided object and will return a map of

     * recordTypeId and recordTypeNames

     * it excludes 'master' record type

     * */

    public static Map<Id, String> recordtypemap;

@AuraEnabled        

    public static Map<Id, String> fetchRecordTypeValues(String objectName, boolean isNewOpportunity){

        List<Schema.RecordTypeInfo> recordtypes = Schema.getGlobalDescribe().get(objectName).getDescribe().getRecordTypeInfos();    

        recordtypemap = new Map<Id, String>();

        //PBI:458359:Modify Quick Actions
        for(RecordTypeInfo rt : recordtypes){
            if(isNewOpportunity){
                if(rt.getName() != 'Master' && rt.getName() != 'Direct' && rt.getName().trim() != '' && rt.isAvailable() == TRUE)
                    if(rt.getName()=='Retail'){
                        recordtypemap.put(rt.getRecordTypeId(), 'Vendor Retail');
                    }else{
                        recordtypemap.put(rt.getRecordTypeId(), rt.getName());
                    }
            }else{
                 if(rt.getName() != 'Master' && rt.getName() != 'New Business Development' && rt.getName() != 'Commercial Finance'  && rt.getName().trim() != ''  && rt.isAvailable() == TRUE)
                    
                        recordtypemap.put(rt.getRecordTypeId(), rt.getName());
                    
            }
            }      

        return recordtypemap;

    }
    
}