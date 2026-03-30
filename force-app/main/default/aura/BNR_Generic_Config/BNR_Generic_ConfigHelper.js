({
    handleColorsInit : function(cmp, event, helper) {
        var elem = cmp.find('customDiv');
        
        switch(cmp.get("v.backgroundcolor")){
            case 'BLACK':
                $A.util.removeClass(elem, 'customDefaultBack');
                $A.util.addClass(elem, 'backBlack');
                break;
            case 'ORANGE':
                $A.util.removeClass(elem, 'customDefaultBack');
                $A.util.addClass(elem, 'backOrange');
                break;
            case 'YELLOW':
                $A.util.removeClass(elem, 'customDefaultBack');
                $A.util.addClass(elem, 'backYellow');
                break;
            case 'GREEN':
                $A.util.removeClass(elem, 'customDefaultBack');
                $A.util.addClass(elem, 'backGreen');
                break;
            case 'GREY':
                $A.util.removeClass(elem, 'customDefaultBack');
                $A.util.addClass(elem, 'backGrey');
                break;
                
        }
        
    },
    
    handleTextColorsInit : function(cmp, event, helper) {
        var elem = cmp.find('customDiv');
        switch(cmp.get("v.textColor")){
            case 'RED':
                $A.util.removeClass(elem, 'customDefaultText');
                $A.util.addClass(elem, 'textRed');
                break;
            case 'ORANGE':
                $A.util.removeClass(elem, 'customDefaultText');
                $A.util.addClass(elem, 'textOrange');
                break;
                
            case 'YELLOW':
                $A.util.removeClass(elem, 'customDefaultText');
                $A.util.addClass(elem, 'textYellow');
                break;
            case 'GREEN':
                $A.util.removeClass(elem, 'customDefaultText');
                $A.util.addClass(elem, 'textGreen');
                break;
            case 'GREY':
                $A.util.removeClass(elem, 'customDefaultText');
                $A.util.addClass(elem, 'textGrey');
                break;
            case 'WHITE':
                $A.util.removeClass(elem, 'customDefaultText');
                $A.util.addClass(elem, 'textWhite');
                break;     
        }
        
    }
 })