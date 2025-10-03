create view AmazonSentiment as
select Id, reviewerName, overall, reviewText,
        day_diff, helpful_yes, helpful_no, total_vote, score_pos_neg_diff, score_average_rating,
        wilson_lower_bound, score as sentimentScore, Sentiment
from amazon a
inner join documentSentiment ds
    on a.[key]=ds.Id