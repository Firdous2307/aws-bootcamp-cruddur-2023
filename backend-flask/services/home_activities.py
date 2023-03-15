from datetime import datetime, timedelta, timezone
from opentelemetry import trace
import logging
from lib.db import pool

tracer = trace.get_tracer("home.activities")

class HomeActivities:
  def run(cognito_user_id=None):
    #Logger.info("HomeActivities")
    with tracer.start_as_current_span("home-activites-mock-data"):
      span = trace.get_current_span()
      now = datetime.now(timezone.utc).astimezone()
      span.set_attribute("app.now", now.isoformat())
      
    sql = """
    SELECT * FROM activities
        """
    with pool.connection() as conn:
        with conn.cursor() as cur:
          cur.execute(sql)
          # this will return a tuple
          # the first field being the data
          json = cur.fetchall()
    return json[0]
    return results()