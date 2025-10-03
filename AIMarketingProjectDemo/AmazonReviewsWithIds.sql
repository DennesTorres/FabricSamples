create view AmazonReviewsWithIds AS
select convert(int,left(right(__filepath__,8),4)) as Id, Classification, Sentiment, PositiveConfidenceScore, 
NeutralConfidenceScore, NegativeConfidenceScore
from AmazonReviews
