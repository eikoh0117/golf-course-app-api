require 'rakuten_web_service'
require 'aws-record'

def lambda_handler(event:, context:)
  date = event['date'].to_s.insert(4, '-').insert(7, '-')
  budget = event['budget']
  departure = event['departure']
  duration = event['duration']

  RakutenWebService.configure do |c|
    c.application_id = ENV['RAKUTEN_APPID']
    c.affiliate_id = ENV['RAKUTEN_AFID']
  end

  matched_plans = []
  plans = RakutenWebService::Gora::Plan.search(maxPrice: budget, playDate: date, areaCode: '8,11,12,13,14', NGPlan: 'planHalfRound,planLesson,planOpenCompe,planRegularCompe')

  begin
    plans.each do |plan|
      plan_duration = SearchGolfApp.find(golf_course_id: plan['golfCourseId']).send("duration#{departure}")
      next if plan_duration > duration

      matched_plans.push(
        {
          plan_name: plan['planInfo'][0]['planName'],
          plan_id: plan['planInfo'][0]['planId'],
          course_name: plan['golfCourseName'],
          caption: plan['golfCourseCaption'],
          prefecture: plan['prefecture'],
          image_url: plan['golfCourseImageUrl'],
          evaluation: plan['evaluation'],
          price: plan['planInfo'][0]['price'],
          duration: plan_duration,
          reserve_url_pc: plan['planInfo'][0]['callInfo']['reservePageUrlPC'],
          stock_count: plan['planInfo'][0]['callInfo']['stockCount'],
        }
      )
    end
  rescue
    return {
      count: 0,
      plans: []
    }
  end

  matched_plans.sort_by! {|plan| plan[:duration]}

  {
     count: matched_plans.count,
     plans: matched_plans
  }
end
