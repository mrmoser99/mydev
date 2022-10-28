({
	doInit : function(component, event, helper) {
  var recordId =   window.location.href.substring(window.location.href.lastIndexOf('/contractprintpdf?=')).split("=")[1];
   component.set("v.recordId",recordId );
        // alert(recordId);
        component.set('v.columns', [
            {label:'Asset Number' , fieldName:'Name', type:'text'},
            {label:'Make' , fieldName:'Asset_Brand_Make__c', type:'text'},
            {label:'Model' , fieldName:'Asset_Model__c', type:'text'},
            {label:'Serial Number' , fieldName:'Asset_Serial_Number__c', type:'text'},
            {label:'Install Date',fieldName:'Install_Date__c',type:'text'},
            {label:'Location Address' , fieldName:'Asset_Install_Address_Line_1__c',type:'text'},
            {label:'Asset Status' , fieldName:'Asset_Status__c',type:'text'}
        ]);
        var action = component.get("c.getContractsAssets");
       // var recordId = component.get("v.recordId");
        action.setParams({
            recordId: recordId,
        });
        action.setCallback(this, function(response){
            var state = response.getState();
        
            if(state==='SUCCESS'){
              var  resp = response.getReturnValue();
                var tabledata = [];
               var list= resp.assetList;
                 console.log('list==>'+JSON.stringify(list));
              
                list.forEach(function(data){
                    console.log('data==>'+JSON.stringify(data));
                    tabledata.push({
                        Name:data.Name,
                        Asset_Brand_Make__c: data.Asset_Brand_Make__c,
                        Asset_Model__c :data.Asset_Model__c,
                        Asset_Serial_Number__c :data.Asset_Serial_Number__c,
                        Install_Date__c :data.Install_Date__c,
                        Asset_Install_Address_Line_1__c :data.Asset_Install_Address_Line_1__c,
                        Asset_Status__c :data.Asset_Status__c
                    });
                });
                
                 component.set("v.data",tabledata) ;
                console.log('geetha'+ JSON.stringify(component.get("v.data")));
                    
                component.set("v.Contract", resp.contract);
                console.log('v.Contract==='+JSON.stringify(component.get("v.Contract")));
            }else{
                
            }
        });
        $A.enqueueAction(action);
		//window.print();
	},
    onPrint: function(component, event, helper) {
        component.set("v.showprintbutton", false);
        window.print();
    },
    onClose:function(component, event, helper) {
        var recordId =  component.get("v.recordId");
      window.location.href=  window.location.href.substring(window.location.href.lastIndexOf('/s'),0)+'/s/contract/'+recordId;
         
    }
})