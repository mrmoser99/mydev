({
    doInit : function(component, event, helper) {
        var recordId=window.location.href.substring(window.location.href.lastIndexOf('/contract/')).split('/')[2];
        window.location.href =	window.location.href.substring(window.location.href.lastIndexOf('/s'),0)+'/s/contractprintpdf?='+recordId;
    }
})