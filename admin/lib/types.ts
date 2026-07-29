export type PostStatus = "live" | "under_review" | "removed";

export interface Neighborhood {
  id: string;
  name: string;
  short_code: string;
  borough: string;
}

export interface User {
  id: string;
  username: string;
  user_number: number;
  home_neighborhood_id: string | null;
  home_changed_at: string | null;
  created_at: string;
  neighborhood?: Neighborhood;
}

export interface Post {
  id: string;
  user_id: string;
  neighborhood_id: string;
  text: string;
  image_url: string | null;
  pin_id: string | null;
  is_daily_prompt: boolean;
  daily_prompt_id: string | null;
  score: number;
  reply_count: number;
  report_count: number;
  status: PostStatus;
  created_at: string;
  author?: { username: string; user_number: number };
  neighborhood?: { name: string };
}

export interface Report {
  id: string;
  reporter_id: string;
  post_id: string;
  reason: string;
  free_text: string | null;
  created_at: string;
  reporter?: { username: string };
}

export interface ModerationPost extends Post {
  reports: Report[];
}
