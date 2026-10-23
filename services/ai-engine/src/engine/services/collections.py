"""Shared vector collection naming."""


def collection_for(project_id: str) -> str:
    """Return the project's vector collection name."""
    return f"proj_{project_id}"
