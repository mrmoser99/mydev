({
	init: function(cmp, evt, helper) {
        var myPageRef = cmp.get("v.pageReference");
        var conList = myPageRef.state.c__contactlist;
        console.log(conList);
        cmp.set("v.contactlist", conList);
    }
})