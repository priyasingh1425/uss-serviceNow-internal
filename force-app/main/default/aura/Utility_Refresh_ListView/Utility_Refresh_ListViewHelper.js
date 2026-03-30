({
   refreshListView : function(component) {
      let navigationItemAPI = component.find("navigationItemAPI");
      navigationItemAPI.getSelectedNavigationItem()
         .then((response) => {
            // Only refresh if viewing an object-page
            const objPage = 'standard__objectPage';
            var objectList = component.get("v.availableForObjects").split(",");
            if (response.pageReference && 
                   response.pageReference.type === objPage  && objectList.includes(response.pageReference.attributes.objectApiName)) {
                // Do the refresh
                navigationItemAPI.refreshNavigationItem()
                    .catch(function(error) {
                        console.log('Error in auto-refresh', error);
                    });
            }
        });
    },
})