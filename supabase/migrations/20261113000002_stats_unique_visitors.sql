-- Update link_stats RPC to include unique_visitors count
create or replace function link_stats(p_link_id bigint)
returns json as $$
  select coalesce(json_build_object(
    'total', count(*),
    'unique_ips', count(distinct ip),
    'unique_visitors', count(distinct visitor_id),
    'first_click', min(clicked_at),
    'last_click', max(clicked_at)
  ), '{"total":0,"unique_ips":0,"unique_visitors":0,"first_click":null,"last_click":null}'::json)
  from clicks where link_id = p_link_id;
$$ language sql stable;
