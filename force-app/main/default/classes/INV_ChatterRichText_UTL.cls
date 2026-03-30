public class INV_ChatterRichText_UTL {
    @InvocableMethod(Label='Share Formatted Chatter Post' Description='Share formatted chatter post which include image, mentions')
    public static List<String> postChatter(List<FlowInput> posts) {
        string communityId,postText;
        system.debug('posts:'+posts);
        if(posts.size()>0)
        {
            for (FlowInput post : posts)
            {
                communityId=null;
                postText=post.postText;
                if(post.subjectIds !=null)
                {
                    for (string recId : post.subjectIds) {
                        INV_ChatterRichText_HLP.postFeedItemWithRichText(communityId, recId, postText);
                    }
                }
            }
        }
        return null;
    }
    
    public class FlowInput
    {
        @InvocableVariable
        public List<string> subjectIds;
        @InvocableVariable
        public string postText;
    }
}