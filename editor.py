import sys
import os

def main():
    filepath = sys.argv[1]
    with open(filepath, 'r') as f:
        lines = f.readlines()

    new_lines = []
    # Commit ranges
    # v0.1.1 block: 48e2913 (pick), 5caf1d8...66b880c (squash)
    # v0.1.3 block: 8887513 (pick), 47b533e...c69cca1 (squash)
    # Docs block:   f919470 (pick), 011e7f3...1adb72a (squash)

    # We need to map short hashes to actions. 
    # Note: rebase todo list has full hashes usually, but instructions use short.
    # We'll match by "starts with".

    # Mapping: { 'hash_prefix': 'action' }
    # Default is pick, so we only need to specify squash changes? 
    # No, we need to explicitly set them because we are rewriting the file.
    
    # Let's define the "Leaders" (Pick)
    leaders = ['48e2913', '8887513', 'f919470']
    
    # We iterate through the lines.
    # The first line (48e2913) is a leader.
    # Subsequent lines until the next leader should be squash.
    
    current_action = 'pick' # Should be pick for the very first one
    
    for line in lines:
        if line.strip().startswith('#') or not line.strip():
            new_lines.append(line)
            continue
        
        parts = line.split()
        if len(parts) < 2:
            new_lines.append(line)
            continue
            
        commit_hash = parts[1]
        
        is_leader = False
        for leader in leaders:
            if commit_hash.startswith(leader):
                is_leader = True
                break
        
        if is_leader:
            new_lines.append(line.replace('pick', 'reword', 1)) # Use reword to edit message
        else:
            new_lines.append(line.replace('pick', 'squash', 1))

    with open(filepath, 'w') as f:
        f.writelines(new_lines)

if __name__ == "__main__":
    main()
