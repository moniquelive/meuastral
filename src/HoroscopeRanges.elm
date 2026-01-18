module HoroscopeRanges exposing (ranges)

import Date exposing (Date, fromCalendarDate)
import Time exposing (Month(..))


ranges : Int -> List ( String, ( Date, Date ) )
ranges year =
    [ ( "aquarius", ( fromCalendarDate year Jan 21, fromCalendarDate year Feb 19 ) )
    , ( "pisces", ( fromCalendarDate year Feb 20, fromCalendarDate year Mar 20 ) )
    , ( "aries", ( fromCalendarDate year Mar 21, fromCalendarDate year Apr 20 ) )
    , ( "taurus", ( fromCalendarDate year Apr 21, fromCalendarDate year May 21 ) )
    , ( "gemini", ( fromCalendarDate year May 22, fromCalendarDate year Jun 21 ) )
    , ( "cancer", ( fromCalendarDate year Jun 22, fromCalendarDate year Jul 22 ) )
    , ( "leo", ( fromCalendarDate year Jul 23, fromCalendarDate year Aug 21 ) )
    , ( "virgo", ( fromCalendarDate year Aug 22, fromCalendarDate year Sep 23 ) )
    , ( "libra", ( fromCalendarDate year Sep 24, fromCalendarDate year Oct 23 ) )
    , ( "scorpio", ( fromCalendarDate year Oct 24, fromCalendarDate year Nov 22 ) )
    , ( "sagittarius", ( fromCalendarDate year Nov 23, fromCalendarDate year Dec 22 ) )
    , ( "capricorn", ( fromCalendarDate year Dec 23, fromCalendarDate year Dec 31 ) )
    , ( "capricorn", ( fromCalendarDate year Jan 1, fromCalendarDate year Jan 20 ) )
    ]
